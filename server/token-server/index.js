// Umigo token server: a tiny HTTP service that sits next to your self-hosted
// LiveKit server. It signs access tokens with YOUR key/secret (no LiveKit Cloud)
// and lists rooms that are live right now for the Home feed.
//
//   POST /token  {room, identity, name, role: "host"|"viewer", title?, tag?, access?, fee?}
//                -> {url, token}
//   GET  /rooms  -> {rooms: [{name, title, hostName, hostId, tag, viewers}]}
//   POST /thumb  (image/png body, Authorization: Bearer <host token>) -> {ok}
//                the host's phone posts a small camera snapshot every ~30s
//   GET  /thumb/<room> -> the latest snapshot (rooms list it as `thumb`: its time, 0 = none)
//   GET  /health -> ok
//
// Env: LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_HOST (internal, e.g. http://livekit:7880),
//      LIVEKIT_PUBLIC_URL (what phones connect to, e.g. wss://live.example.com), PORT (default 3001)
//
// Later this logic moves into the NestJS backend (auth, wallet, gifts in Postgres).
import http from 'node:http';
import { readFileSync } from 'node:fs';
import { AccessToken, RoomServiceClient, TokenVerifier } from 'livekit-server-sdk';

const KEY = process.env.LIVEKIT_API_KEY || 'devkey';
const SECRET = process.env.LIVEKIT_API_SECRET || 'secret';
const HOST = process.env.LIVEKIT_HOST || 'http://127.0.0.1:7880';
const PUBLIC_URL = process.env.LIVEKIT_PUBLIC_URL || 'ws://127.0.0.1:7880';
const PORT = Number(process.env.PORT || 3001);

const rooms = new RoomServiceClient(HOST, KEY, SECRET);
const verifier = new TokenVerifier(KEY, SECRET);

// Latest camera snapshot per live room, in memory: {buf, type, at}. Dropped when the live ends.
const thumbs = new Map();
const THUMB_MAX = 1_500_000;
// Bans written by the Umi Guard moderator (server/moderator/data/bans.json).
const BANS = process.env.BANS_FILE || new URL('../moderator/data/bans.json', import.meta.url).pathname;
function activeBan(identity) {
  try {
    const b = JSON.parse(readFileSync(BANS, 'utf8'))[String(identity).split('~')[0]];
    return b && b.until > Date.now() ? b : null;
  } catch {
    return null;
  }
}

const send = (res, code, body) => {
  res.writeHead(code, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type, authorization',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
  });
  res.end(JSON.stringify(body));
};

const readJson = (req) =>
  new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (c) => {
      raw += c;
      if (raw.length > 10_000) reject(new Error('body too large'));
    });
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch (e) {
        reject(e);
      }
    });
  });

const readBytes = (req, max) =>
  new Promise((resolve, reject) => {
    const parts = [];
    let n = 0;
    req.on('data', (c) => {
      n += c.length;
      if (n > max) {
        reject(Object.assign(new Error('image too large'), { code: 413 }));
        req.destroy();
      } else parts.push(c);
    });
    req.on('end', () => resolve(Buffer.concat(parts)));
    req.on('error', reject);
  });

// Only the room's host (a valid host token for that room) may post its snapshot.
async function saveThumb(req) {
  const auth = String(req.headers.authorization || '');
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  let claims;
  try {
    claims = await verifier.verify(token);
  } catch {
    throw Object.assign(new Error('bad token'), { code: 401 });
  }
  const room = claims.video?.room;
  let role = '';
  try {
    role = JSON.parse(claims.metadata || '{}').role;
  } catch {
    /* ignore */
  }
  if (!room || role !== 'host' || !claims.video?.canPublish) throw Object.assign(new Error('only the host can post a thumbnail'), { code: 403 });
  const type = String(req.headers['content-type'] || '');
  if (!['image/png', 'image/jpeg', 'image/webp'].includes(type)) throw Object.assign(new Error('png, jpeg or webp only'), { code: 415 });
  const buf = await readBytes(req, THUMB_MAX);
  if (buf.length < 100) throw Object.assign(new Error('empty image'), { code: 400 });
  thumbs.set(room, { buf, type, at: Date.now() });
  return { ok: true };
}

function sendThumb(res, room) {
  const t = thumbs.get(room);
  if (!t) return send(res, 404, { error: 'no thumbnail' });
  res.writeHead(200, { 'content-type': t.type, 'cache-control': 'public, max-age=30', 'access-control-allow-origin': '*' });
  res.end(t.buf);
}

const clean = (s, max = 64) => String(s ?? '').replace(/[^\p{L}\p{N} ._\-#!?,'&~]/gu, '').slice(0, max);

async function issueToken(body) {
  const room = clean(body.room, 80).replace(/\s/g, '_');
  const identity = clean(body.identity, 80).replace(/\s/g, '_');
  if (!room || !identity) throw Object.assign(new Error('room and identity are required'), { code: 400 });
  const host = body.role === 'host';
  const name = clean(body.name, 40) || 'Guest';
  if (identity.startsWith('umi-guard')) throw Object.assign(new Error('reserved identity'), { code: 400 });
  const b = activeBan(identity);
  if (b && (b.scope === 'all' || host)) {
    const mins = Math.ceil((b.until - Date.now()) / 60000);
    throw Object.assign(new Error(`You are blocked for ${mins} more min (${b.reason})`), { code: 403 });
  }

  if (host) {
    // Create (or update) the room with metadata the Home feed shows.
    const access = ['public', 'paid', 'subscribers'].includes(body.access) ? body.access : 'public';
    const fee = Math.max(0, Math.min(100000, parseInt(body.fee, 10) || 0));
    const metadata = JSON.stringify({ title: clean(body.title, 60), tag: clean(body.tag, 20), hostName: name, hostId: identity, access, fee });
    try {
      await rooms.createRoom({ name: room, emptyTimeout: 60, maxParticipants: 5000, metadata });
    } catch {
      /* already exists */
    }
    try {
      await rooms.updateRoomMetadata(room, metadata);
    } catch {
      /* ignore */
    }
  }

  const at = new AccessToken(KEY, SECRET, { identity, name, ttl: '6h', metadata: JSON.stringify({ role: host ? 'host' : 'viewer' }) });
  at.addGrant({
    room,
    roomJoin: true,
    canPublish: host, // only the host sends camera/mic
    canSubscribe: true,
    canPublishData: true, // everyone can chat, like and send gifts
    roomCreate: host,
  });
  return { url: PUBLIC_URL, token: await at.toJwt() };
}

async function listRooms() {
  const list = await rooms.listRooms();
  const live = new Set(list.map((r) => r.name));
  for (const k of thumbs.keys()) if (!live.has(k)) thumbs.delete(k); // live ended
  const out = [];
  for (const r of list) {
    let meta = {};
    try {
      meta = JSON.parse(r.metadata || '{}');
    } catch {
      /* ignore */
    }
    if (!meta.hostId) continue; // only Umigo live rooms
    // only show rooms whose host is actually in the room
    let hostHere = false;
    let viewers = 0;
    try {
      const ps = await rooms.listParticipants(r.name);
      hostHere = ps.some((p) => p.identity === meta.hostId);
      viewers = ps.filter((p) => p.identity !== meta.hostId && !p.identity.startsWith('umi-guard')).length;
    } catch {
      /* ignore */
    }
    if (!hostHere) continue;
    out.push({
      name: r.name,
      title: meta.title || '',
      tag: meta.tag || '',
      hostName: meta.hostName || 'Host',
      hostId: meta.hostId,
      access: meta.access || 'public', // shown as a lock on Home; the app checks payment (server ledger comes with the backend)
      fee: meta.fee || 0,
      viewers,
      startedAt: Number(r.creationTime || 0) * 1000, // ms, newest first in the app's "New" tab
      thumb: thumbs.get(r.name)?.at || 0, // the app loads /thumb/<name>?v=<thumb>
    });
  }
  return out;
}

http
  .createServer(async (req, res) => {
    const path = new URL(req.url, 'http://x').pathname.replace(/^\/api/, '');
    try {
      if (req.method === 'OPTIONS') return send(res, 204, {});
      if (req.method === 'GET' && path === '/health') return send(res, 200, { ok: true });
      if (req.method === 'GET' && path === '/rooms') return send(res, 200, { rooms: await listRooms() });
      if (req.method === 'POST' && path === '/thumb') return send(res, 200, await saveThumb(req));
      if (req.method === 'GET' && path.startsWith('/thumb/')) return sendThumb(res, decodeURIComponent(path.slice(7)));
      if (req.method === 'POST' && path === '/token') return send(res, 200, await issueToken(await readJson(req)));
      return send(res, 404, { error: 'not found' });
    } catch (e) {
      console.error(e);
      return send(res, e.code || 500, { error: e.message });
    }
  })
  .listen(PORT, () => console.log(`umigo token server on :${PORT} -> ${HOST} (public ${PUBLIC_URL})`));
