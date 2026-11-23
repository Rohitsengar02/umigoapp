// Umi Guard: free, self-hosted, real-time moderation for Umigo live rooms.
//
// It joins every live room on your LiveKit server as a participant ("umi-guard") and:
//  * CHAT  - viewers send chat to the guard; the guard filters (words, links, numbers,
//            spam, slow mode) and re-broadcasts clean messages in ~10-30 ms.
//            Strikes: 3 -> muted 5 min, 5 -> kicked + banned 1 h.
//  * HOST  - the host can mute / unmute / kick / ban viewers, set slow mode and add words.
//  * VIDEO - samples the host camera ~1 frame/s, runs the open-source NSFW model
//            (nsfwjs MobileNetV2, on CPU). Two unsafe frames in a row -> camera is muted
//            by the server and viewers see a blur. 3 video strikes -> live ended + 24 h ban.
// No paid APIs. Everything runs on your VPS.
import { mkdirSync, readFileSync, writeFileSync, appendFileSync } from 'node:fs';
import { AccessToken, RoomServiceClient } from 'livekit-server-sdk';
import { Room, RoomEvent, TrackKind, VideoStream, VideoBufferType } from '@livekit/rtc-node';
import * as tf from '@tensorflow/tfjs-node';
import * as nsfwjs from 'nsfwjs';
import sharp from 'sharp';
import { checkMessage, RateLimiter } from './filter.js';

const KEY = process.env.LIVEKIT_API_KEY || 'devkey';
const SECRET = process.env.LIVEKIT_API_SECRET || 'secret';
const HOST = process.env.LIVEKIT_HOST || 'http://127.0.0.1:7880';
const WS = HOST.replace(/^http/, 'ws');
const NSFW_THRESHOLD = Number(process.env.NSFW_THRESHOLD ?? 0.7); // Porn + Hentai score
const SEXY_THRESHOLD = Number(process.env.SEXY_THRESHOLD ?? 0.92);
const CHECK_EVERY_MS = Number(process.env.CHECK_EVERY_MS ?? 1000);
const DATA = process.env.DATA_DIR || new URL('./data/', import.meta.url).pathname;
const GUARD_ID = 'umi-guard';
mkdirSync(DATA, { recursive: true });

const svc = new RoomServiceClient(HOST, KEY, SECRET);
const enc = new TextEncoder();
const dec = new TextDecoder();
const log = (...a) => console.log(new Date().toISOString(), ...a);
const userKey = (identity) => String(identity).split('~')[0];

// ---- bans (shared with the token server through data/bans.json) ----
const BANS = `${DATA}bans.json`;
const readBans = () => {
  try {
    return JSON.parse(readFileSync(BANS, 'utf8'));
  } catch {
    return {};
  }
};
function ban(identity, ms, scope, reason) {
  const b = readBans();
  b[userKey(identity)] = { until: Date.now() + ms, scope, reason };
  writeFileSync(BANS, JSON.stringify(b, null, 1));
}
const report = (obj) => appendFileSync(`${DATA}reports.jsonl`, JSON.stringify({ at: new Date().toISOString(), ...obj }) + '\n');

// ---- NSFW model (loaded once) ----
let model = null;
async function loadModel() {
  model = await nsfwjs.load('MobileNetV2');
  log('nsfw model ready (MobileNetV2)');
}

class RoomGuard {
  constructor(info) {
    this.name = info.name;
    const meta = JSON.parse(info.metadata || '{}');
    this.hostId = meta.hostId;
    this.hostName = meta.hostName || 'Host';
    this.room = new Room();
    this.limiter = new RateLimiter();
    this.strikes = new Map();
    this.muted = new Map(); // userKey -> until
    this.slow = 0;
    this.words = [];
    this.video = { blocked: false, paused: false, hits: 0, clean: 0, strikes: 0, busy: false, last: 0, trackSid: null };
    this.closed = false;
  }

  async start() {
    const at = new AccessToken(KEY, SECRET, { identity: GUARD_ID, name: 'Umi Guard', metadata: JSON.stringify({ role: 'guard' }) });
    at.addGrant({ room: this.name, roomJoin: true, canSubscribe: true, canPublish: false, canPublishData: true, roomAdmin: true });
    const r = this.room;
    r.on(RoomEvent.DataReceived, (payload, p, _kind, topic) => this.onData(payload, p, topic).catch((e) => log('data err', e.message)));
    r.on(RoomEvent.TrackSubscribed, (track, pub, p) => {
      if (track.kind === TrackKind.KIND_VIDEO && p.identity === this.hostId) {
        this.video.trackSid = pub.sid;
        // fresh guard (e.g. after a restart): lift any pause left by the previous one
        if (pub.muted) svc.mutePublishedTrack(this.name, this.hostId, pub.sid, false).catch(() => {});
        this.watchVideo(track).catch((e) => log('video err', e.message));
      }
    });
    // late joiners get the current moderation state
    r.on(RoomEvent.ParticipantConnected, (p) => {
      const to = [p.identity];
      this.send({ t: 'mod', a: 'guard_on', x: 'Umi Guard is moderating this live' }, to).catch(() => {});
      if (this.slow) this.send({ t: 'mod', a: 'slow', sec: this.slow, x: `set slow mode to ${this.slow}s` }, to).catch(() => {});
      if (this.video.blocked) this.send({ t: 'mod', a: 'video_block', x: 'Video paused by Umi Guard (community rules)', strikes: this.video.strikes }, to).catch(() => {});
    });
    r.on(RoomEvent.ParticipantDisconnected, (p) => {
      if (p.identity === this.hostId) this.stop('host left');
    });
    r.on(RoomEvent.Disconnected, () => this.stop('disconnected'));
    await r.connect(WS, await at.toJwt(), { autoSubscribe: true, dynacast: false });
    log(`guard joined ${this.name} (host ${this.hostName})`);
    await this.send({ t: 'mod', a: 'guard_on', x: 'Umi Guard is moderating this live' });
    await this.send({ t: 'mod', a: 'video_ok', x: 'Video is back' }); // clean slate for viewers
    if (this.hostId) await this.send({ t: 'mod', a: 'video_resume', x: '' }, [this.hostId]).catch(() => {});
  }

  async stop(why) {
    if (this.closed) return;
    this.closed = true;
    guards.delete(this.name);
    log(`guard left ${this.name}: ${why}`);
    try {
      await this.room.disconnect();
    } catch {
      /* ignore */
    }
  }

  async send(obj, to) {
    if (this.closed) return;
    const opts = { reliable: true, topic: 'umigo' };
    if (to && to.length) opts.destination_identities = to;
    await this.room.localParticipant.publishData(enc.encode(JSON.stringify(obj)), opts);
  }

  everyoneExcept(identity) {
    return [...this.room.remoteParticipants.values()].map((p) => p.identity).filter((i) => i !== identity);
  }

  isMuted(identity) {
    const until = this.muted.get(userKey(identity));
    if (!until) return false;
    if (Date.now() > until) {
      this.muted.delete(userKey(identity));
      return false;
    }
    return true;
  }

  async strike(identity, name, reason) {
    const k = userKey(identity);
    const n = (this.strikes.get(k) || 0) + 1;
    this.strikes.set(k, n);
    report({ room: this.name, user: k, name, reason, strikes: n });
    if (n >= 5) return this.kick(identity, name, 'repeated violations', 60 * 60 * 1000);
    if (n >= 3) return this.mute(identity, name, 5 * 60, `muted for 5 min: ${reason}`);
    await this.send({ t: 'mod', a: 'warn', who: identity, x: `Warning ${n}/3: ${reason}` }, [identity]);
  }

  async mute(identity, name, sec, reason) {
    this.muted.set(userKey(identity), Date.now() + sec * 1000);
    await this.send({ t: 'mod', a: 'muted', who: identity, n: name, sec, x: reason });
  }

  async kick(identity, name, reason, banMs = 0) {
    if (identity === this.hostId) return;
    await this.send({ t: 'mod', a: 'kicked', who: identity, n: name, x: reason });
    if (banMs) ban(identity, banMs, 'all', reason);
    try {
      await svc.removeParticipant(this.name, identity);
    } catch (e) {
      log('kick failed', e.message);
    }
  }

  async onData(payload, p, topic) {
    if (!p) return;
    const from = p.identity;
    let m;
    try {
      m = JSON.parse(dec.decode(payload));
    } catch {
      return;
    }

    if (topic === 'umigo-mod-in' && m.t === 'chat') {
      const name = String(m.n || p.name || 'Someone').slice(0, 30);
      if (this.isMuted(from)) return this.send({ t: 'mod', a: 'removed', id: m.id, who: from, x: 'You are muted right now' }, [from]);
      const rl = this.limiter.check(userKey(from), String(m.x || ''), from === this.hostId ? 0 : this.slow);
      if (!rl.ok) {
        await this.send({ t: 'mod', a: 'removed', id: m.id, who: from, x: rl.reason }, [from]);
        if (rl.strike) await this.strike(from, name, rl.reason);
        return;
      }
      const r = checkMessage(m.x, { customWords: this.words });
      if (r.action === 'block') {
        await this.send({ t: 'mod', a: 'removed', id: m.id, who: from, x: `Removed: ${r.reason}` }, [from]);
        return this.strike(from, name, r.reason);
      }
      const out = { t: 'chat', id: m.id, n: name, lv: Number(m.lv) || 1, x: r.text, s: from };
      await this.send(out, this.everyoneExcept(from));
      if (r.action === 'mask') {
        await this.send({ t: 'mod', a: 'mask', id: m.id, who: from, x: r.text }, [from]);
        if (r.reason === 'abusive language') await this.strike(from, name, r.reason);
      }
      return;
    }

    if (topic === 'umigo-mod-cmd') {
      if (from !== this.hostId) return; // only the host (identity comes from the server, can't be faked)
      const who = String(m.who || '');
      switch (m.cmd) {
        case 'mute':
          return this.mute(who, m.n, Number(m.sec) || 600, `${this.hostName} muted ${m.n || 'a viewer'}`);
        case 'unmute':
          this.muted.delete(userKey(who));
          this.strikes.delete(userKey(who));
          return this.send({ t: 'mod', a: 'unmuted', who, n: m.n, x: `${m.n || 'Viewer'} can chat again` });
        case 'kick':
          return this.kick(who, m.n, `removed by ${this.hostName}`);
        case 'ban':
          return this.kick(who, m.n, `banned by ${this.hostName}`, 7 * 24 * 3600 * 1000);
        case 'slow':
          this.slow = Math.max(0, Math.min(60, Number(m.sec) || 0));
          return this.send({ t: 'mod', a: 'slow', sec: this.slow, x: this.slow ? `set slow mode to ${this.slow}s` : "turned slow mode off" });
        case 'words':
          this.words = (m.words || []).map(String).slice(0, 200);
          return this.send({ t: 'mod', a: 'info', x: `Blocked words updated (${this.words.length})` }, [from]);
      }
      return;
    }

    if (topic === 'umigo-report') {
      report({ room: this.name, by: userKey(from), target: m.who || this.hostId, reason: m.x || 'report' });
      return this.send({ t: 'mod', a: 'info', x: 'Thanks, Umi Guard got your report.' }, [from]);
    }
  }

  // ---- real-time video moderation ----
  async watchVideo(track) {
    log(`watching host video in ${this.name}`);
    const stream = new VideoStream(track);
    for await (const ev of stream) {
      if (this.closed) break;
      const now = Date.now();
      if (this.video.busy || now - this.video.last < CHECK_EVERY_MS || !model) continue;
      this.video.last = now;
      this.video.busy = true;
      this.classify(ev.frame)
        .then((s) => this.onScores(s))
        .catch((e) => log('classify err', e.message))
        .finally(() => (this.video.busy = false));
    }
  }

  async classify(frame) {
    const rgba = frame.convert(VideoBufferType.RGBA);
    const rgb = await sharp(Buffer.from(rgba.data.buffer, rgba.data.byteOffset, rgba.data.byteLength), {
      raw: { width: rgba.width, height: rgba.height, channels: 4 },
    })
      .removeAlpha()
      .resize(224, 224, { fit: 'cover' })
      .raw()
      .toBuffer();
    const img = tf.tensor3d(new Uint8Array(rgb), [224, 224, 3], 'int32');
    try {
      const preds = await model.classify(img, 5);
      return Object.fromEntries(preds.map((p) => [p.className, p.probability]));
    } finally {
      img.dispose();
    }
  }

  async onScores(s) {
    const unsafe = (s.Porn || 0) + (s.Hentai || 0) >= NSFW_THRESHOLD || (s.Sexy || 0) >= SEXY_THRESHOLD;
    const v = this.video;
    if (process.env.DEBUG_SCORES) log(this.name, JSON.stringify(s));
    if (unsafe) {
      v.clean = 0;
      v.hits++;
      if (!v.paused && v.hits >= 2) await this.blockVideo(s);
    } else {
      v.hits = 0;
      if (v.blocked && ++v.clean >= 3) {
        v.blocked = false;
        await this.send({ t: 'mod', a: 'video_ok', x: 'Video is back' });
        log(`video ok again in ${this.name}`);
      }
    }
  }

  async blockVideo(s) {
    const v = this.video;
    v.blocked = true; // viewers blurred until 3 clean frames
    v.paused = true; // host camera muted until the resume timer
    v.strikes++;
    report({ room: this.name, user: this.hostId, reason: 'nsfw video', scores: s, strikes: v.strikes });
    log(`NSFW video in ${this.name} (strike ${v.strikes})`, JSON.stringify(s));
    await this.send({ t: 'mod', a: 'video_block', x: 'Video paused by Umi Guard (community rules)', strikes: v.strikes });
    try {
      if (v.trackSid) await svc.mutePublishedTrack(this.name, this.hostId, v.trackSid, true);
    } catch (e) {
      log('mute track failed', e.message);
    }
    if (v.strikes >= 3) {
      await this.send({ t: 'mod', a: 'end', x: 'Live ended for breaking the nudity rules 3 times' });
      ban(this.hostId, 24 * 3600 * 1000, 'live', 'nsfw video');
      setTimeout(() => svc.deleteRoom(this.name).catch(() => {}), 1500);
      return;
    }
    // let the host try again after a short pause; viewers stay blurred until 3 clean frames
    setTimeout(() => {
      v.hits = 0;
      v.paused = false;
      this.send({ t: 'mod', a: 'video_resume', x: 'You can turn your camera back on. Keep it clean!' }, [this.hostId]).catch(() => {});
    }, 8000);
  }
}

const guards = new Map();

async function tick() {
  let rooms = [];
  try {
    rooms = await svc.listRooms();
  } catch (e) {
    return log('listRooms failed', e.message);
  }
  for (const r of rooms) {
    let meta = {};
    try {
      meta = JSON.parse(r.metadata || '{}');
    } catch {
      /* ignore */
    }
    if (!meta.hostId || guards.has(r.name) || r.numParticipants === 0) continue;
    const g = new RoomGuard(r);
    guards.set(r.name, g);
    g.start().catch((e) => {
      log('join failed', r.name, e.message);
      guards.delete(r.name);
    });
  }
}

await loadModel();
await tick();
setInterval(tick, Number(process.env.POLL_MS ?? 1500));
log(`Umi Guard running -> ${HOST} (nsfw threshold ${NSFW_THRESHOLD}, every ${CHECK_EVERY_MS} ms)`);
