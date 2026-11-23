import 'package:flutter_test/flutter_test.dart';
import 'package:umigo/moderation/chat_filter.dart';

void main() {
  const cases = {
    'your voice is magic': ModAction.allow,
    'grand idea bro': ModAction.allow,
    'I am 25 from Delhi': ModAction.allow,
    'scunthorpe classic cocktail': ModAction.allow,
    'you are a f.u.c.k.i.n.g idiot': ModAction.mask,
    'fuuuuck you': ModAction.mask,
    'f4ck this': ModAction.mask,
    'you are a f4cking legend': ModAction.mask,
    'ye gana bahut ganda hai': ModAction.allow,
    'gande kapde': ModAction.allow,
    'bc kya kar raha': ModAction.mask,
    'tu chutiya hai': ModAction.mask,
    'चूतिया है तू': ModAction.mask,
    'm a d a r c h o d': ModAction.block,
    'follow me www.spam.xyz': ModAction.block,
    'call 98765 43210 now': ModAction.block,
    'whatsapp pe aao': ModAction.block,
    'send nudes': ModAction.block,
    'free coins here': ModAction.block,
    'kys loser': ModAction.block,
    'HELLO EVERYONE WELCOME HERE': ModAction.mask,
  };
  for (final e in cases.entries) {
    test(e.key, () => expect(ChatFilter.check(e.key).action, e.value));
  }
  test('rate limiter blocks repeats and slow mode', () {
    final r = ChatRateLimiter();
    expect(r.check('hi'), isNull);
    expect(r.check('hi'), isNull);
    expect(r.check('hi'), isNotNull);
    final s = ChatRateLimiter();
    expect(s.check('a', slowSec: 3), isNull);
    expect(s.check('b', slowSec: 3), isNotNull);
  });
}
