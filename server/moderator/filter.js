// Umigo chat filter (server copy). Same rules as lib/moderation/chat_filter.dart in the app.
// Pure JS, no network, ~0.05 ms per message.
import { readFileSync } from 'node:fs';

const LISTS = JSON.parse(readFileSync(new URL('./wordlist.json', import.meta.url), 'utf8'));

const LEET = { 0: 'o', 1: 'i', 3: 'e', 4: 'a', 5: 's', 7: 't', 8: 'b', '@': 'a', $: 's', '!': 'i', '|': 'i', '+': 't' };

/** lowercase, map leetspeak, squeeze repeated letters (fuuuck -> fuck) */
export function normalize(text) {
  let s = String(text).toLowerCase().normalize('NFKC');
  s = s.replace(/[0134578@$!|+]/g, (c) => LEET[c] ?? c);
  s = s.replace(/(\p{L})\1{2,}/gu, '$1$1'); // keep doubles like "loo", squeeze 3+
  return s;
}

const words = (list) => list.map((w) => normalize(w));
const sets = {
  profanity: words(LISTS.profanity),
  hate: words(LISTS.hate),
  sexual: words(LISTS.sexual),
  contact: words(LISTS.contact),
  scam: words(LISTS.scam),
};

const tokenize = (s) => s.split(/[^\p{L}\p{M}\p{N}]+/u).filter(Boolean);
// "f u c k", "f.u.c.k", "f-u-c-k" -> "fuck"
const compact = (s) => s.replace(/[^\p{L}\p{M}\p{N}]+/gu, '');
const squeeze = (s) => s.replace(/(\p{L})\1+/gu, '$1');

const SUFFIX = /^(ing|in|ings|er|ers|ed|s|es|iya|ya|yan)$/;

function hit(norm, tokens, comp, list) {
  for (const w of list) {
    if (w.includes(' ') || w.includes('.')) {
      if (norm.includes(w) || comp.includes(compact(w))) return w;
      continue;
    }
    // short words (bc, mc, kys) only as whole tokens to avoid false positives
    if (tokens.includes(w) || tokens.some((t) => squeeze(t) === squeeze(w))) return w;
    // word + common ending: facking, chutiyas, bitchy, randiyan
    if (w.length >= 4 && tokens.some((t) => t.startsWith(w) && SUFFIX.test(t.slice(w.length)))) return w;
    if (w.length >= 6 && comp.includes(w)) return w;
  }
  return null;
}

const URL_RE = /(https?:\/\/|www\.)\S+|\b[a-z0-9-]+\.(com|in|net|org|io|me|co|xyz|link|live|app|site|ly|gg)\b/i;
const PHONE_RE = /(?:\+?91[\s-]?)?(?:\d[\s-]?){10,}/;
const EMAIL_RE = /\b[\w.+-]+@[\w-]+\.[\w.]+\b/;

/**
 * @returns {{action: 'allow'|'mask'|'block', reason?: string, text: string}}
 *  allow: send as is; mask: send with bad words replaced; block: drop it and give a strike.
 */
export function checkMessage(text, opts = {}) {
  const raw = String(text ?? '').trim().slice(0, 200);
  if (!raw) return { action: 'block', reason: 'empty', text: '' };
  const norm = normalize(raw);
  const tokens = tokenize(norm);
  const comp = compact(norm);
  const extra = (opts.customWords || []).map(normalize);

  if (URL_RE.test(raw)) return { action: 'block', reason: 'links are not allowed', text: raw };
  if (PHONE_RE.test(raw.replace(/[^\d+\s-]/g, ' '))) return { action: 'block', reason: 'phone numbers are not allowed', text: raw };
  if (EMAIL_RE.test(raw)) return { action: 'block', reason: 'emails are not allowed', text: raw };
  if (hit(norm, tokens, comp, sets.hate)) return { action: 'block', reason: 'hate or threats', text: raw };
  if (hit(norm, tokens, comp, sets.sexual)) return { action: 'block', reason: 'sexual content', text: raw };
  if (hit(norm, tokens, comp, sets.scam)) return { action: 'block', reason: 'scam or fraud', text: raw };
  if (hit(norm, tokens, comp, sets.contact)) return { action: 'block', reason: 'sharing contacts off the app', text: raw };

  const letters = raw.replace(/[^A-Za-z]/g, '');
  if (letters.length >= 12 && letters.replace(/[^A-Z]/g, '').length / letters.length > 0.8) {
    return { action: 'mask', reason: 'too much caps', text: raw.toLowerCase() };
  }

  // mask profanity word by word
  const all = [...sets.profanity, ...extra];
  let masked = raw;
  let found = false;
  for (const part of raw.split(/(\s+)/)) {
    const n = normalize(part);
    const t = tokenize(n);
    if (hit(n, t, compact(n), all)) {
      found = true;
      masked = masked.replace(part, '✱'.repeat(Math.min(6, Math.max(3, part.length))));
    }
  }
  if (!found && hit(norm, tokens, comp, all)) {
    return { action: 'block', reason: 'abusive language', text: raw }; // hidden across spaces
  }
  if (found) return { action: 'mask', reason: 'abusive language', text: masked };
  return { action: 'allow', text: raw };
}

/** Per-user flood/duplicate/slow-mode limiter. */
export class RateLimiter {
  constructor() {
    this.users = new Map();
  }
  check(user, text, slowModeSec = 0) {
    const now = Date.now();
    const u = this.users.get(user) || { times: [], last: '', repeats: 0 };
    this.users.set(user, u);
    u.times = u.times.filter((t) => now - t < 10_000);
    if (slowModeSec > 0 && u.times.length && now - u.times[u.times.length - 1] < slowModeSec * 1000) {
      return { ok: false, reason: `slow mode: wait ${slowModeSec}s between messages`, strike: false };
    }
    if (u.times.length >= 6) return { ok: false, reason: 'you are sending messages too fast', strike: true };
    const key = normalize(text).replace(/\s+/g, ' ');
    u.repeats = key === u.last ? u.repeats + 1 : 0;
    u.last = key;
    if (u.repeats >= 2) return { ok: false, reason: 'no repeating the same message', strike: true };
    u.times.push(now);
    return { ok: true };
  }
}
