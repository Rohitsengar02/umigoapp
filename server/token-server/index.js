// Umigo token server: a tiny HTTP service that sits next to your self-hosted
// LiveKit server. It signs access tokens with YOUR key/secret (no LiveKit Cloud)
// and lists rooms that are live right now for the Home feed.
//
//   POST /token  {room, identity, name, role: "host"|"viewer", title?, tag?}
//                -> {url, token}
//   GET  /rooms  -> {rooms: [{name, title, hostName, hostId, tag, viewers}]}
//   GET  /health -> ok
//
// Env: LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_HOST (internal, e.g. http://livekit:7880),
//      LIVEKIT_PUBLIC_URL (what phones connect to, e.g. wss://live.example.com), PORT (default 3001)
//
// Later this logic moves into the NestJS backend (auth, wallet, gifts in Postgres).
import http from 'node:http';
import { AccessToken, RoomServiceClient } from 'livekit-server-sdk';

const KEY = process.env.LIVEKIT_API_KEY || 'devkey';
const SECRET = process.env.LIVEKIT_API_SECRET || 'secret';
const HOST = process.env.LIVEKIT_HOST || 'http://127.0.0.1:7880';
const PUBLIC_URL = process.env.LIVEKIT_PUBLIC_URL || 'ws://127.0.0.1:7880';
const PORT = Number(process.env.PORT || 3001);

const rooms = new RoomServiceClient(HOST, KEY, SECRET);

const send = (res, code, body) => {
  res.writeHead(code, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type',
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

const clean = (s, max = 64) => String(s ?? '').replace(/[^\p{L}\p{N} ._\-#!?,'&]/gu, '').slice(0, max);

async function issueToken(body) {
  const room = clean(body.room, 80).replace(/\s/g, '_');
  const identity = clean(body.identity, 80).replace(/\s/g, '_');
  if (!room || !identity) throw Object.assign(new Error('room and identity are required'), { code: 400 });
  const host = body.role === 'host';
  const name = clean(body.name, 40) || 'Guest';

  if (host) {
    // Create (or update) the room with metadata the Home feed shows.
    const metadata = JSON.stringify({ title: clean(body.title, 60), tag: clean(body.tag, 20), hostName: name, hostId: identity });
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
    try {
      const ps = await rooms.listParticipants(r.name);
      hostHere = ps.some((p) => p.identity === meta.hostId);
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
      viewers: Math.max(0, (r.numParticipants || 1) - 1),
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
      if (req.method === 'POST' && path === '/token') return send(res, 200, await issueToken(await readJson(req)));
      return send(res, 404, { error: 'not found' });
    } catch (e) {
      console.error(e);
      return send(res, e.code || 500, { error: e.message });
    }
  })
  .listen(PORT, () => console.log(`umigo token server on :${PORT} -> ${HOST} (public ${PUBLIC_URL})`));
