import '../data/social_data.dart';

/// One line of a host's tip menu, e.g. "Song request · 50 coins".
class TipItem {
  final String label;
  final int coins;
  const TipItem(this.label, this.coins);
  Map<String, dynamic> toJson() => {'l': label, 'c': coins};
  static TipItem fromJson(Map<String, dynamic> j) => TipItem('${j['l'] ?? ''}', (j['c'] ?? 0) as int);
}

const defaultTips = [TipItem('Say my name', 20), TipItem('Song request', 50), TipItem('Shout-out', 100), TipItem('Dance / dare', 300)];

/// Everything the host chose in the Go live steps. The host's phone sends it to
/// each viewer as a `setup` data message when they join (topic `umigo`).
/// Payment checks are client-side until the backend owns the ledger.
class LiveSetup {
  String mode; // Video, Audio room, PK battle
  String title, tag;
  LiveAccess access;
  int entryFee; // coins, for paid private lives
  int subPrice; // coins / month, for subscriber lives
  List<TipItem> tips;
  bool tipsOn;
  bool goalOn;
  String goalLabel;
  int goalCoins;
  int goalStart; // coins already counted when a viewer joins
  bool followersChat, coHost, saveReplay, showTopGifters;

  LiveSetup({
    this.mode = 'Video',
    this.title = '',
    this.tag = 'Music',
    this.access = LiveAccess.public,
    this.entryFee = 49,
    this.subPrice = 199,
    List<TipItem>? tips,
    this.tipsOn = true,
    this.goalOn = true,
    this.goalLabel = 'New mic fund',
    this.goalCoins = 5000,
    this.goalStart = 0,
    this.followersChat = false,
    this.coHost = true,
    this.saveReplay = true,
    this.showTopGifters = true,
  }) : tips = tips ?? List.of(defaultTips);

  bool get isPrivate => access != LiveAccess.public;

  Map<String, dynamic> toJson() => {
    't': 'setup',
    'm': mode,
    'a': access.name,
    'fee': entryFee,
    'sub': subPrice,
    'tips': tipsOn ? [for (final t in tips) t.toJson()] : [],
    'goal': goalOn ? {'l': goalLabel, 'c': goalCoins, 's': goalStart} : null,
    'fc': followersChat,
    'co': coHost,
    'top': showTopGifters,
  };

  static LiveSetup fromJson(Map<String, dynamic> j) {
    final goal = j['goal'] as Map<String, dynamic>?;
    final tips = [for (final t in (j['tips'] as List? ?? const [])) TipItem.fromJson(t as Map<String, dynamic>)];
    return LiveSetup(
      mode: '${j['m'] ?? 'Video'}',
      access: LiveAccess.values.where((a) => a.name == j['a']).firstOrNull ?? LiveAccess.public,
      entryFee: (j['fee'] ?? 0) as int,
      subPrice: (j['sub'] ?? 0) as int,
      tips: tips,
      tipsOn: tips.isNotEmpty,
      goalOn: goal != null,
      goalLabel: '${goal?['l'] ?? ''}',
      goalCoins: (goal?['c'] ?? 0) as int,
      goalStart: (goal?['s'] ?? 0) as int,
      followersChat: j['fc'] == true,
      coHost: j['co'] == true,
      showTopGifters: j['top'] != false,
    );
  }

  /// What a demo creator's live looks like to a viewer.
  static LiveSetup forCreator(Creator? c) {
    if (c == null) return LiveSetup(goalStart: 3120);
    return LiveSetup(
      access: c.access,
      entryFee: c.entryFee,
      subPrice: c.subPrice,
      goalLabel: switch (c.cat) {
        'Music' => 'New guitar strings',
        'Gaming' => 'Squad tournament entry',
        'Talk' => 'Café meetup for fans',
        _ => 'Tonight’s goal',
      },
      goalCoins: 5000,
      goalStart: 1800 + c.followers % 2600,
      tips: switch (c.cat) {
        'Music' => const [TipItem('Say my name', 20), TipItem('Song request', 50), TipItem('Dedication', 100), TipItem('Full song in my style', 500)],
        'Gaming' => const [TipItem('Pick my weapon', 30), TipItem('Join the squad', 150), TipItem('No-scope dare', 300)],
        _ => null,
      },
    );
  }
}
