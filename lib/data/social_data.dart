// Demo social data: creators, reels, chats and activity. Swap for API calls when
// the NestJS backend lands (see the system design doc: users, follows, reels,
// conversations, notifications tables).

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class Category {
  final String name, blurb;
  final IconData icon;
  final Color tint;
  final int lives;
  final String img;
  const Category(this.name, this.icon, this.tint, this.lives, this.img, this.blurb);
}

const allCategories = <Category>[
  Category('Music', Icons.music_note_rounded, Color(0xFF8E4FA0), 342, 'assets/img/priya.jpg', 'Covers, originals, requests'),
  Category('Talk', Icons.forum_rounded, Color(0xFF12A15F), 518, 'assets/img/kabir.jpg', 'Chill chats and AMAs'),
  Category('Gaming', Icons.sports_esports_rounded, Color(0xFF3B6FE0), 276, 'assets/img/crew.jpg', 'BGMI, Valorant, chess'),
  Category('Dance', Icons.nightlife_rounded, Color(0xFFF2711C), 154, 'assets/img/dev.jpg', 'Bollywood, hip-hop, garba'),
  Category('Comedy', Icons.sentiment_very_satisfied_rounded, Color(0xFFD99A00), 98, 'assets/img/rahul.jpg', 'Stand-up and roasts'),
  Category('Study', Icons.menu_book_rounded, Color(0xFF6B4A6E), 121, 'assets/img/ananya.jpg', 'Study with me, focus rooms'),
  Category('Fitness', Icons.fitness_center_rounded, Color(0xFF0E9C9B), 67, 'assets/img/sana.jpg', 'Yoga, HIIT, form checks'),
  Category('Cooking', Icons.restaurant_rounded, Color(0xFFD9485F), 59, 'assets/img/meera.jpg', 'Home recipes, live kitchens'),
  Category('Travel', Icons.flight_takeoff_rounded, Color(0xFF2D8CFF), 44, 'assets/img/beach.jpg', 'IRL walks and sunsets'),
  Category('Astrology', Icons.auto_awesome_rounded, Color(0xFF7A3FD1), 38, 'assets/img/zara.jpg', 'Tarot and kundli readings'),
];

Category categoryByName(String n) => allCategories.firstWhere((c) => c.name == n, orElse: () => allCategories.first);

const regions = ['All India', 'Delhi NCR', 'Mumbai', 'Bengaluru', 'Uttar Pradesh', 'Punjab', 'Gujarat', 'West Bengal', 'Tamil Nadu', 'Kerala'];

/// Who can watch a live.
enum LiveAccess { public, paid, subscribers }

class Creator {
  final String id, name, handle, img, bio, cat, region;
  final int followers, following, posts;
  final bool verified, privateAccount, live;
  final String liveDays, liveTime;

  /// Coins a fan pays once to open a chat. 0 = free.
  final int chatPrice;

  /// Coins per month for subscriber-only lives and posts.
  final int subPrice;
  final LiveAccess access;
  final int entryFee;
  final List<String> photos;
  const Creator({
    required this.id,
    required this.name,
    required this.handle,
    required this.img,
    required this.bio,
    required this.cat,
    required this.region,
    required this.followers,
    required this.following,
    required this.posts,
    this.verified = false,
    this.privateAccount = false,
    this.live = false,
    this.liveDays = 'Mon–Fri',
    this.liveTime = '9:00 PM',
    this.chatPrice = 29,
    this.subPrice = 199,
    this.access = LiveAccess.public,
    this.entryFee = 0,
    this.photos = const [],
  });
}

const _pics = [
  'assets/img/priya.jpg',
  'assets/img/kabir.jpg',
  'assets/img/zara.jpg',
  'assets/img/ananya.jpg',
  'assets/img/dev.jpg',
  'assets/img/crew.jpg',
  'assets/img/beach.jpg',
  'assets/img/meera.jpg',
  'assets/img/sana.jpg',
  'assets/img/rahul.jpg',
  'assets/img/kabir2.jpg',
  'assets/img/ava.jpg',
];

List<String> _gallery(int start, int n) => [for (var i = 0; i < n; i++) _pics[(start + i * 5) % _pics.length]];

final creators = <Creator>[
  Creator(
    id: 'priya',
    name: 'Priya Rao',
    handle: 'priya.r',
    img: 'assets/img/priya.jpg',
    bio: 'Acoustic covers every night 🎸 Requests open in live. Mumbai.',
    cat: 'Music',
    region: 'Mumbai',
    followers: 248000,
    following: 182,
    posts: 214,
    verified: true,
    live: true,
    liveTime: '10:00 PM',
    liveDays: 'Daily',
    chatPrice: 49,
    subPrice: 299,
    photos: _gallery(0, 12),
  ),
  Creator(
    id: 'kabir',
    name: 'Kabir Verma',
    handle: 'kabir_v',
    img: 'assets/img/kabir.jpg',
    bio: 'Café chats, life advice, PK battles on weekends ☕️',
    cat: 'Talk',
    region: 'Delhi NCR',
    followers: 131000,
    following: 410,
    posts: 96,
    verified: true,
    live: true,
    access: LiveAccess.paid,
    entryFee: 49,
    liveDays: 'Sat, Sun',
    liveTime: '8:30 PM',
    photos: _gallery(1, 9),
  ),
  Creator(
    id: 'zara',
    name: 'Zara Shaikh',
    handle: 'zara.s',
    img: 'assets/img/zara.jpg',
    bio: 'Slow songs at golden hour. Subscriber lives every Friday 💜',
    cat: 'Music',
    region: 'Mumbai',
    followers: 89400,
    following: 98,
    posts: 143,
    live: true,
    access: LiveAccess.subscribers,
    subPrice: 249,
    chatPrice: 39,
    liveDays: 'Fri',
    liveTime: '7:00 PM',
    photos: _gallery(2, 12),
  ),
  Creator(
    id: 'ananya',
    name: 'Ananya Jain',
    handle: 'ananya.studies',
    img: 'assets/img/ananya.jpg',
    bio: 'Study with me · UPSC 2027 · pomodoro rooms 📚',
    cat: 'Study',
    region: 'Uttar Pradesh',
    followers: 52100,
    following: 221,
    posts: 61,
    privateAccount: true,
    chatPrice: 0,
    liveDays: 'Mon–Sat',
    liveTime: '6:00 AM',
    photos: _gallery(3, 6),
  ),
  Creator(
    id: 'dev',
    name: 'Dev Malhotra',
    handle: 'rj.dev',
    img: 'assets/img/dev.jpg',
    bio: 'Beach nights, dance challenges, Goa vibes 🌊',
    cat: 'Dance',
    region: 'Punjab',
    followers: 77800,
    following: 305,
    posts: 188,
    live: true,
    liveDays: 'Wed, Fri',
    liveTime: '11:00 PM',
    photos: _gallery(4, 12),
  ),
  Creator(
    id: 'crew',
    name: 'The Crew',
    handle: 'thecrew.gg',
    img: 'assets/img/crew.jpg',
    bio: 'Squad games, dinner parties, chaos. Bengaluru 🎮',
    cat: 'Gaming',
    region: 'Bengaluru',
    followers: 45200,
    following: 12,
    posts: 77,
    liveDays: 'Daily',
    liveTime: '9:30 PM',
    chatPrice: 19,
    photos: _gallery(5, 9),
  ),
  Creator(
    id: 'meera',
    name: 'Meera Iyer',
    handle: 'meera.cooks',
    img: 'assets/img/meera.jpg',
    bio: 'South Indian home kitchen, live every Sunday brunch 🍛',
    cat: 'Cooking',
    region: 'Tamil Nadu',
    followers: 38900,
    following: 140,
    posts: 120,
    liveDays: 'Sun',
    liveTime: '11:00 AM',
    photos: _gallery(7, 9),
  ),
  Creator(
    id: 'sana',
    name: 'Sana Kapoor',
    handle: 'sana.fit',
    img: 'assets/img/sana.jpg',
    bio: 'Morning yoga + HIIT. Form checks in my lives 🧘‍♀️',
    cat: 'Fitness',
    region: 'Gujarat',
    followers: 61200,
    following: 87,
    posts: 230,
    access: LiveAccess.subscribers,
    subPrice: 149,
    liveDays: 'Mon–Fri',
    liveTime: '6:30 AM',
    photos: _gallery(8, 12),
  ),
  Creator(
    id: 'rahul',
    name: 'Rahul Khanna',
    handle: 'rahul_k',
    img: 'assets/img/rahul.jpg',
    bio: 'Stand-up bits and roast battles. Lucknow 🎤',
    cat: 'Comedy',
    region: 'Uttar Pradesh',
    followers: 102000,
    following: 260,
    posts: 84,
    live: true,
    liveDays: 'Thu',
    liveTime: '9:00 PM',
    photos: _gallery(9, 9),
  ),
];

Creator? creatorById(String id) => creators.where((c) => c.id == id).firstOrNull;

class Reel {
  final String id, creatorId, img, caption, song, cat;
  final int likes, comments, shares;
  final double focusY;
  const Reel(this.id, this.creatorId, this.img, this.caption, this.song, this.cat, this.likes, this.comments, this.shares, {this.focusY = 0});
  Creator get creator => creatorById(creatorId) ?? creators.first;
}

const reels = <Reel>[
  Reel(
    'r1',
    'priya',
    'assets/img/priya.jpg',
    'Kesariya, but make it lo-fi 🎧 #acoustic #requests',
    'Kesariya · Priya Rao (cover)',
    'Music',
    48200,
    1204,
    830,
    focusY: -.4,
  ),
  Reel('r2', 'dev', 'assets/img/dev.jpg', 'Fairy lights, sand, one take. Tag your dance partner 🌊', 'Original audio · rj.dev', 'Dance', 31800, 642, 1220),
  Reel('r3', 'kabir', 'assets/img/kabir.jpg', 'Asked 100 strangers their best advice. #3 hit hard ☕️', 'Coffee talk · kabir_v', 'Talk', 22600, 2310, 940),
  Reel('r4', 'zara', 'assets/img/zara.jpg', 'Golden hour by the lake. Friday sub live is a full set 💜', 'Tum Hi Ho · Zara (live)', 'Music', 19400, 488, 310),
  Reel('r5', 'crew', 'assets/img/crew.jpg', 'When the squad finally clutches 😭 #bgmi #squadgoals', 'Original audio · thecrew.gg', 'Gaming', 15300, 902, 600),
  Reel('r6', 'ananya', 'assets/img/ananya.jpg', '6 AM study room, 4 pomodoros. Join tomorrow? 📚', 'Lo-fi beats · study mix', 'Study', 9800, 320, 120),
  Reel('r7', 'meera', 'assets/img/meera.jpg', 'Sunday brunch: crispy ghee dosa in 60 seconds 🍛', 'Original audio · meera.cooks', 'Cooking', 27400, 1530, 2100),
  Reel('r8', 'rahul', 'assets/img/rahul.jpg', 'Lucknow aunties vs Delhi aunties 😂 part 2', 'Original audio · rahul_k', 'Comedy', 56100, 4402, 5300),
  Reel('r9', 'sana', 'assets/img/sana.jpg', '5-minute morning flow, no mat needed 🧘‍♀️', 'Calm · Sana Kapoor', 'Fitness', 12900, 211, 410),
];

const reelComments = [
  ('Meera', 'assets/img/meera.jpg', 'this is so good 😍', '2m', 182),
  ('arjun_07', '', 'part 2 please!!', '5m', 64),
  ('Rahul_K', 'assets/img/rahul.jpg', 'the vibe 🔥🔥', '12m', 41),
  ('Sana', 'assets/img/sana.jpg', 'saving this for later', '30m', 22),
  ('Kiran', '', 'when is the next live?', '1h', 9),
];

class ChatMsg {
  final String text;
  final bool mine;
  final String time;
  final String? giftId;
  const ChatMsg(this.text, this.mine, this.time, {this.giftId});
}

class Convo {
  final String creatorId;
  final List<ChatMsg> msgs;
  int unread;
  Convo(this.creatorId, this.msgs, {this.unread = 0});
  Creator get creator => creatorById(creatorId) ?? creators.first;
  String get last => msgs.isEmpty ? '' : msgs.last.text;
  String get time => msgs.isEmpty ? '' : msgs.last.time;
}

/// In-memory chats for the demo.
final convos = <Convo>[
  Convo('priya', [const ChatMsg('Thank you for the Rocket!! 💗', false, '9:12 PM')], unread: 2),
  Convo('kabir', [const ChatMsg('PK tomorrow at 9?', false, '8:40 PM')], unread: 1),
  Convo('zara', []),
  Convo('dev', []),
  Convo('ananya', [const ChatMsg('Good luck with the exam!', true, 'Mon'), const ChatMsg('thank you 🙏', false, 'Mon')]),
  Convo('meera', []),
];

Convo convoFor(String creatorId) {
  final c = convos.where((c) => c.creatorId == creatorId).firstOrNull;
  if (c != null) return c;
  final n = Convo(creatorId, []);
  convos.insert(0, n);
  return n;
}

const autoReplies = ['hehe thank you 💗', 'see you in my live tonight!', 'aww that made my day', 'yes!! join at 10', 'haha true 😂'];

class Activity {
  final String kind, who, img, title, sub, when, group;
  final bool unread;
  const Activity(this.kind, this.who, this.img, this.title, this.sub, this.when, this.group, {this.unread = false});
}

const activities = <Activity>[
  Activity('live', 'priya', 'assets/img/priya.jpg', 'Priya Rao is live now', 'Late night acoustic covers · 12.4K watching', '1m', 'Today', unread: true),
  Activity(
    'pk',
    'kabir',
    'assets/img/kabir2.jpg',
    'Kabir_v challenged you to a PK',
    '5-minute battle, winner gets 2× gift points tonight.',
    '2m',
    'Today',
    unread: true,
  ),
  Activity('gift', 'rahul', 'assets/img/rahul.jpg', 'Rahul_K sent you Rocket ×3', '+1,498 diamonds added to your earnings.', '18m', 'Today', unread: true),
  Activity('follow', 'meera', 'assets/img/meera.jpg', 'Meera and 183 others followed you', 'From your live “Sunday night requests”.', '1h', 'Today'),
  Activity('like', 'sana', 'assets/img/sana.jpg', 'Sana liked your reel', '“Sunday night requests” highlight', '3h', 'Today'),
  Activity('sub', 'zara', 'assets/img/zara.jpg', 'Your subscription to Zara renews Friday', '249 coins · cancel any time in Profile.', '1d', 'This week'),
  Activity('comment', 'dev', 'assets/img/dev.jpg', 'Dev commented: “that high note 🔥”', 'On your reel', '2d', 'This week'),
  Activity('money', '', '', 'Withdrawal processing', '₹2,000 to HDFC ••• 2210. Arrives within 24 hours.', '2d', 'This week'),
  Activity('level', '', '', 'You reached Level 12', 'New badge unlocked. 660 XP to Level 13.', '4d', 'This week'),
];

Color accessColor(LiveAccess a) => switch (a) {
  LiveAccess.public => UC.green,
  LiveAccess.paid => UC.accent,
  LiveAccess.subscribers => const Color(0xFF8E4FA0),
};
