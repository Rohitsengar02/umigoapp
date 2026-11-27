import 'package:material_ui/material_ui.dart';

import '../data/social_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';
import 'creator_profile_screen.dart';
import 'reels_screen.dart';

/// Notifications: lives, gifts, follows, comments, money. Opened from the bell.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

const _filters = {
  'All': <String>[],
  'Lives': ['live', 'pk'],
  'Gifts': ['gift', 'money', 'sub'],
  'Follows': ['follow'],
  'Comments': ['comment', 'like'],
};

class _ActivityScreenState extends State<ActivityScreen> {
  String filter = 'All';
  bool read = false;
  bool? pk;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final kinds = _filters[filter]!;
    final list = activities.where((a) => kinds.isEmpty || kinds.contains(a.kind)).toList();
    final groups = <String, List<Activity>>{};
    for (final a in list) {
      groups.putIfAbsent(a.group, () => []).add(a);
    }
    final unread = activities.where((a) => a.unread).length;
    return Scaffold(
      body: AuroraBg(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ...staggerSlivers([
              SliverToBoxAdapter(
                child: LargeTitle(
                  'Activity',
                  eyebrow: read ? 'All caught up' : '$unread new',
                  actions: [
                    Pressable(
                      onTap: () => setState(() => read = true),
                      label: 'Mark all read',
                      child: Glass(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Text(
                          'Mark all read',
                          style: ts(13.5, w: FontWeight.w800, c: UC.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 58,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    children: [
                      for (final f in _filters.keys)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChipX(f, on: f == filter, onTap: () => setState(() => filter = f)),
                        ),
                    ],
                  ),
                ),
              ),
            ]),
            for (final g in groups.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(g.key, style: ts(15, w: FontWeight.w800)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(
                  children: [for (final (i, a) in g.value.indexed) StaggerIn(index: i, child: _row(context, a))],
                ),
              ),
            ],
            if (list.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    'Nothing here yet',
                    textAlign: TextAlign.center,
                    style: ts(15, w: FontWeight.w700, c: UC.muted),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: pad.bottom + 24)),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _badge(String kind) => switch (kind) {
    'live' => (Icons.sensors_rounded, UC.primary),
    'pk' => (Icons.bolt_rounded, const Color(0xFF7A3FD1)),
    'gift' => (Icons.card_giftcard_rounded, UC.accent),
    'follow' => (Icons.person_add_alt_1_rounded, const Color(0xFF3B8BFF)),
    'like' => (Icons.favorite_rounded, const Color(0xFFFF3B6B)),
    'comment' => (Icons.mode_comment_rounded, UC.green),
    'sub' => (Icons.workspace_premium_rounded, const Color(0xFF8E4FA0)),
    'money' => (Icons.currency_rupee_rounded, UC.greenText),
    _ => (Icons.emoji_events_rounded, UC.gold),
  };

  Widget _row(BuildContext context, Activity a) {
    final (icon, tint) = _badge(a.kind);
    final c = creatorById(a.who);
    final fresh = a.unread && !read;
    Widget? action;
    if (a.kind == 'live' && c != null) {
      action = _btn('Watch', true, () => openCreatorLive(context, c));
    } else if (a.kind == 'follow' && c != null) {
      final f = AppState.I.isFollowing(c.id);
      action = _btn(f ? 'Following' : 'Follow back', !f, () => setState(() => AppState.I.toggleFollow(c.id, c.name)));
    } else if (a.kind == 'pk') {
      action = pk == null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _btn('Accept', true, () {
                  setState(() => pk = true);
                  toast(context, 'PK accepted. Starts when you both go live.');
                }),
                const SizedBox(width: 6),
                _btn('Later', false, () => setState(() => pk = false)),
              ],
            )
          : Text(
              pk! ? 'Accepted' : 'Declined',
              style: ts(12.5, w: FontWeight.w800, c: pk! ? UC.greenText : UC.muted),
            );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fresh ? UC.primary.withValues(alpha: .35) : Colors.white),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: InkWell(
        onTap: c == null ? null : () => openCreator(context, c.id),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  a.img.isNotEmpty
                      ? Avatar(img: a.img, size: 50)
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: tint.withValues(alpha: .14), shape: BoxShape.circle),
                          child: Icon(icon, color: tint),
                        ),
                  if (a.img.isNotEmpty)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: tint,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(icon, size: 11, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: ts(14.5, w: FontWeight.w800, h: 1.25)),
                  const SizedBox(height: 2),
                  Text(
                    '${a.sub} · ${a.when}',
                    style: ts(12.5, w: FontWeight.w500, c: UC.muted, h: 1.3),
                  ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action],
            if (fresh && action == null)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(color: UC.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String t, bool filled, VoidCallback onTap) => Pressable(
    onTap: onTap,
    label: t,
    child: Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: filled ? UC.brandGradient : null, color: filled ? null : UC.surface, borderRadius: BorderRadius.circular(99)),
      child: Text(
        t,
        style: ts(12.5, w: FontWeight.w800, c: filled ? Colors.white : UC.ink),
      ),
    ),
  );
}
