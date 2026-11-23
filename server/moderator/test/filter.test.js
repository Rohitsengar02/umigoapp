import assert from 'node:assert/strict';
import { checkMessage, RateLimiter } from '../filter.js';
const cases = [
  ['your voice is magic', 'allow'],
  ['grand idea bro', 'allow'],
  ['I am 25 from Delhi', 'allow'],
  ['scunthorpe classic cocktail', 'allow'],
  ['you are a f.u.c.k.i.n.g idiot', 'mask'],
  ['fuuuuck you', 'mask'],
  ['f4ck this', 'mask'],
  ['you are a f4cking legend', 'mask'],
  ['ye gana bahut ganda hai', 'allow'],
  ['gande kapde', 'allow'],
  ['bc kya kar raha', 'mask'],
  ['tu chutiya hai', 'mask'],
  ['चूतिया है तू', 'mask'],
  ['m a d a r c h o d', 'block'],
  ['follow me www.spam.xyz', 'block'],
  ['call 98765 43210 now', 'block'],
  ['whatsapp pe aao', 'block'],
  ['send nudes', 'block'],
  ['free coins here', 'block'],
  ['kys loser', 'block'],
  ['HELLO EVERYONE WELCOME HERE', 'mask'],
];
let fail = 0;
for (const [t, want] of cases) {
  const r = checkMessage(t);
  const ok = r.action === want;
  if (!ok) fail++;
  console.log(ok ? 'ok  ' : 'FAIL', want.padEnd(5), '|', t, '->', r.action, r.reason || '', r.action === 'mask' ? `"${r.text}"` : '');
}
const rl = new RateLimiter();
assert.equal(rl.check('u', 'hi').ok, true);
assert.equal(rl.check('u', 'hi').ok, true);
assert.equal(rl.check('u', 'hi').ok, false); // third repeat
assert.equal(rl.check('s', 'a', 3).ok, true);
assert.equal(rl.check('s', 'b', 3).ok, false); // slow mode
console.log(fail ? `${fail} failed` : 'all filter tests passed');
process.exit(fail ? 1 : 0);
