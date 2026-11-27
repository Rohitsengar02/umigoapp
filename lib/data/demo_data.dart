// Demo data for every screen. Swap these for API calls when the NestJS backend lands.

class Host {
  final String id, name, img, title, where, views, cat;
  final double posY;
  const Host(this.id, this.name, this.img, this.title, this.where, this.views, this.cat, {this.posY = -0.4});
}

const demoHosts = <Host>[
  Host('priya', 'Priya.r', 'assets/img/priya.jpg', 'Late night acoustic covers', 'Mumbai', '12.4K', 'Music', posY: -0.6),
  Host('kabir', 'Kabir_v', 'assets/img/kabir.jpg', 'Café chats, ask me anything', 'Delhi', '8.1K', 'Chat'),
  Host('zara', 'Zara S', 'assets/img/zara.jpg', 'Lake sunset, slow songs', 'Pune', '5.6K', 'Music'),
  Host('ananya', 'Ananya', 'assets/img/ananya.jpg', 'Study with me', 'Jaipur', '3.2K', 'Chat'),
  Host('dev', 'Dev', 'assets/img/dev.jpg', 'Fairy lights beach night', 'Goa', '2.9K', 'Dance'),
  Host('crew', 'The Crew', 'assets/img/crew.jpg', 'Friday dinner party', 'Bengaluru', '2.1K', 'Gaming'),
];

class Story {
  final String name, img;
  final bool live;
  const Story(this.name, this.img, this.live);
}

const demoStories = <Story>[
  Story('Priya.r', 'assets/img/priya.jpg', true),
  Story('Kabir_v', 'assets/img/kabir.jpg', true),
  Story('Zara S', 'assets/img/zara.jpg', true),
  Story('Meera', 'assets/img/meera.jpg', false),
  Story('Rahul_K', 'assets/img/rahul.jpg', false),
  Story('Sana', 'assets/img/sana.jpg', false),
];

const categories = ['For you', 'Nearby', 'Music', 'Gaming', 'Dance', 'Chat', 'New'];

class Gift {
  final String id, name;
  final int price;
  final String? tag;
  final String tab;
  const Gift(this.id, this.name, this.price, {this.tag, this.tab = 'Popular'});
}

const gifts = <Gift>[
  Gift('rose', 'Rose', 1),
  Gift('heart', 'Heart', 5),
  Gift('coffee', 'Chai', 10),
  Gift('star', 'Star', 49, tag: 'HOT'),
  Gift('crown', 'Crown', 299),
  Gift('rocket', 'Rocket', 999, tag: 'PK'),
  Gift('ring', 'Ring', 2999),
  Gift('car', 'Supercar', 9999),
];

Gift giftById(String id) => gifts.firstWhere((g) => g.id == id, orElse: () => gifts.first);

class CoinPack {
  final int coins, price, bonus;
  final String? tag;
  const CoinPack(this.coins, this.price, this.bonus, [this.tag]);
}

const coinPacks = <CoinPack>[
  CoinPack(100, 10, 0),
  CoinPack(600, 59, 30),
  CoinPack(1200, 119, 80),
  CoinPack(3000, 299, 300, 'POPULAR'),
  CoinPack(6000, 589, 750),
  CoinPack(12000, 1149, 1800, 'BEST VALUE'),
];

class Tx {
  final String day, kind, title, sub, amt, status;
  const Tx(this.day, this.kind, this.title, this.sub, this.amt, this.status);
}

const demoTx = <Tx>[
  Tx('Today', 'rc', 'Recharge · 6,000 coins', '8:14 PM · UPI ••• 4821', '+6,750', 'Success'),
  Tx('Today', 'gs', 'Rocket ×3 to Priya.r', '7:52 PM · in live', '−2,997', 'Sent'),
  Tx('Today', 'gr', 'Gifts received in your live', '6:30 PM · diamonds from 57 gifters', '+4,210', 'Credited'),
  Tx('Today', 'bn', 'Daily check-in · Day 4', '9:01 AM', '+10', 'Bonus'),
  Tx('Yesterday', 'wd', 'Withdrawal to HDFC ••• 2210', '4:12 PM · 20,000 diamonds', '−₹2,000', 'Processing'),
  Tx('Yesterday', 'gs', 'Crown to Kabir_v', '11:40 PM · PK battle', '−299', 'Sent'),
  Tx('Yesterday', 'rc', 'Recharge · 1,200 coins', '10:02 PM · Google Play', '+1,280', 'Success'),
];

class Ranked {
  final int rank, lv;
  final String name, img, score;
  const Ranked(this.rank, this.name, this.img, this.lv, this.score);
}

const demoRanks = <Ranked>[
  Ranked(1, 'Priya.r', 'assets/img/priya.jpg', 44, '2.6M'),
  Ranked(2, 'Kabir_v', 'assets/img/kabir.jpg', 40, '1.8M'),
  Ranked(3, 'Zara S', 'assets/img/zara.jpg', 39, '1.2M'),
  Ranked(4, 'Ananya', 'assets/img/ananya_av.jpg', 38, '980K'),
  Ranked(5, 'RJ Dev', 'assets/img/dev_av.jpg', 33, '742K'),
  Ranked(6, 'Meera', 'assets/img/meera.jpg', 29, '610K'),
  Ranked(7, 'Sana', 'assets/img/sana.jpg', 27, '488K'),
  Ranked(8, 'Rahul_K', 'assets/img/rahul.jpg', 41, '402K'),
];

/// Lines the demo bots say in a simulated live room.
const botViewers = [
  ('Meera', 24, 'assets/img/meera.jpg'),
  ('arjun_07', 8, ''),
  ('Rahul_K', 41, 'assets/img/rahul.jpg'),
  ('Sana', 15, 'assets/img/sana.jpg'),
  ('Kiran', 12, ''),
  ('Ishaan', 6, ''),
  ('Nisha', 19, ''),
];

const botLines = [
  'your voice is magic',
  'play Kesariya next please',
  'hello from Lucknow!',
  'first time here, loving it',
  'can you say hi to me?',
  'this lighting is so good',
  'PK tonight?',
  'sending love from Chennai',
  'haha that was funny',
  'one more song please!',
];

String fmtIn(num n) {
  final s = n.round().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

String fmtK(int n) {
  String one(double v) => v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  if (n >= 1000000) return '${one(n / 1000000)}M';
  if (n >= 1000) return '${one(n / 1000)}K';
  return '$n';
}
