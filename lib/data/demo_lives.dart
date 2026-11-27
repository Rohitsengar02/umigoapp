// Demo lives shown next to real ones until the backend lists real creators.
// Each one opens that creator's demo live (with their access rules).

import '../live/token_api.dart';
import 'social_data.dart';

final _t0 = DateTime.now().millisecondsSinceEpoch;

/// (creator id, title, viewers, minutes since it started)
const _demo = [
  ('priya', 'Late night acoustic covers 🎸', 12400, 74),
  ('kabir', 'Café chats, ask me anything', 8100, 41),
  ('rahul', 'Roasting your DMs 😂', 6900, 3),
  ('zara', 'Golden hour, slow songs', 5600, 118),
  ('dev', 'Bhangra night, request a song', 4300, 9),
  ('ananya', 'Study with me · 50/10 pomodoro', 3200, 26),
  ('crew', 'BGMI squad, join the lobby', 2900, 1),
  ('meera', 'Sunday biryani, cook along', 1800, 14),
  ('sana', 'Morning yoga flow', 1200, 6),
];

final demoLives = <LiveRoomInfo>[
  for (final (id, title, viewers, mins) in _demo)
    () {
      final c = creatorById(id)!;
      return LiveRoomInfo(
        name: 'demo_$id',
        title: title,
        hostName: c.name.startsWith('The ') ? c.name : c.name.split(' ').first,
        hostId: c.id,
        tag: c.cat,
        viewers: viewers,
        startedAt: _t0 - mins * 60000,
        access: c.access.name,
        fee: c.access == LiveAccess.subscribers ? c.subPrice : c.entryFee,
        img: c.img,
        demoId: c.id,
      );
    }(),
];
