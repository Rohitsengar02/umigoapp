import 'package:flutter_test/flutter_test.dart';
import 'package:umigo/live/fx.dart';
import 'package:umigo/live/live_session.dart';

void main() {
  test('filter settings survive a save and load', () {
    final s = FxSettings.glam.copyWith(look: 'vintage', sticker: 'crown');
    final back = FxSettings.fromJson(s.toJson());
    expect(back, s);
    expect(back.any, isTrue);
    expect(const FxSettings().any, isFalse);
  });

  test('presets keep the chosen look and sticker', () {
    final s = const FxSettings(look: 'mono', sticker: 'cat').withBeauty(FxSettings.natural);
    expect(s.look, 'mono');
    expect(s.sticker, 'cat');
    expect(s.smooth, FxSettings.natural.smooth);
  });

  test('nudity thresholds', () {
    expect(LiveSession.unsafeScores({'Neutral': .9, 'Porn': .05}), isFalse);
    expect(LiveSession.unsafeScores({'Porn': .5, 'Hentai': .25}), isTrue);
    expect(LiveSession.unsafeScores({'Sexy': .95}), isTrue);
    expect(LiveSession.unsafeScores({'Sexy': .8, 'Neutral': .2}), isFalse);
  });

  test('viewer identities map to one user', () {
    expect(LiveSession.userKey('u123456~4821'), 'u123456');
    expect(LiveSession.userKey('u123456'), 'u123456');
  });
}
