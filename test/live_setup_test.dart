import 'package:flutter_test/flutter_test.dart';
import 'package:umigo/data/social_data.dart';
import 'package:umigo/live/live_session.dart';

void main() {
  test('live setup survives the trip to a viewer', () {
    final s = LiveSetup(mode: 'PK battle', access: LiveAccess.paid, entryFee: 99, goalCoins: 2500, goalLabel: 'Mic', goalStart: 300, followersChat: true)
      ..tips.add(const TipItem('Dance', 300));
    final back = LiveSetup.fromJson(s.toJson());
    expect(back.mode, 'PK battle');
    expect(back.access, LiveAccess.paid);
    expect(back.entryFee, 99);
    expect(back.tips.last.label, 'Dance');
    expect(back.tips.length, defaultTips.length + 1);
    expect(back.goalOn, isTrue);
    expect(back.goalCoins, 2500);
    expect(back.goalStart, 300);
    expect(back.followersChat, isTrue);
  });

  test('tips and goal can be switched off', () {
    final back = LiveSetup.fromJson(LiveSetup(tipsOn: false, goalOn: false).toJson());
    expect(back.tipsOn, isFalse);
    expect(back.goalOn, isFalse);
    expect(back.isPrivate, isFalse);
  });

  test('a tip counts its coins, a chat counts none', () {
    expect(LiveEvent(LiveEventType.tip, 'a', text: 'Song request', qty: 50).coins, 50);
    expect(LiveEvent(LiveEventType.chat, 'a', text: 'hi').coins, 0);
    final j = LiveEvent(LiveEventType.tip, 'a', text: 'Shout-out', qty: 100).toJson();
    final e = LiveEvent.fromJson(j, 'viewer1')!;
    expect(e.type, LiveEventType.tip);
    expect(e.coins, 100);
  });
}
