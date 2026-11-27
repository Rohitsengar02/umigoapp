import 'package:material_ui/material_ui.dart';

import '../live/rooms_feed.dart';
import '../live/token_api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_cards.dart';
import '../widgets/motion.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui.dart';
import 'categories_screen.dart';
import 'leaderboard_screen.dart';
import 'wallet_screen.dart';

/// Side menu from the sketch.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    void go(Widget page) {
      Navigator.pop(context);
      Navigator.push(context, umiRoute((_) => page));
    }

    final top = <(IconData, String, VoidCallback)>[
      (
        Icons.collections_bookmark_rounded,
        'My collection',
        () => go(const InfoScreen('My collection', Icons.collections_bookmark_rounded, 'Clips and gifts you saved from lives will show here.')),
      ),
      (Icons.favorite_rounded, 'My favourite', () => go(const LiveListScreen(kind: LiveListKind.favourite))),
      (Icons.local_fire_department_rounded, 'Trending', () => go(const LiveListScreen(kind: LiveListKind.trending))),
      (Icons.grid_view_rounded, 'Categories', () => go(const CategoriesScreen())),
      (Icons.history_rounded, 'Watch history', () => go(const WatchHistoryScreen())),
      (Icons.auto_awesome_rounded, 'Recommended', () => go(const LiveListScreen(kind: LiveListKind.recommended))),
      (Icons.lock_rounded, 'Best for private', () => go(const LiveListScreen(kind: LiveListKind.private))),
      (Icons.emoji_events_rounded, 'Leaderboard', () => go(const WithBack(LeaderboardScreen()))),
      (Icons.insights_rounded, 'Statistics', () => go(const WithBack(WalletScreen()))),
    ];
    final bottom = <(IconData, String, VoidCallback)>[
      (
        Icons.card_giftcard_rounded,
        'Refer & earn',
        () => go(
          InfoScreen('Refer & earn', Icons.card_giftcard_rounded, 'Share your code ${st.displayId}. You and your friend each get 100 coins when they join.'),
        ),
      ),
      (
        Icons.campaign_rounded,
        'Announcements',
        () => go(const InfoScreen('Announcements', Icons.campaign_rounded, 'New: Umi Guard now keeps every live safe, in chat and on video.')),
      ),
      (
        Icons.workspace_premium_rounded,
        'Subscription',
        () => go(const InfoScreen('Subscription', Icons.workspace_premium_rounded, 'Umigo Premium with private lives and premium hosts is coming soon.')),
      ),
      (
        Icons.star_rounded,
        'Rate Umigo',
        () {
          Navigator.pop(context);
          toast(context, 'Thank you! Rating opens in the Play Store once Umigo is published.');
        },
      ),
    ];

    return Drawer(
      backgroundColor: UC.bg,
      width: 312,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(34))),
      clipBehavior: Clip.antiAlias,
      child: AuroraBg(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(14, MediaQuery.paddingOf(context).top + 14, 14, 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UC.primary, Color(0xFFE5677F), UC.accent]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .3), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Avatar(img: 'assets/img/me.jpg', name: st.name, size: 56, border: Colors.white, borderW: 2.5),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ds(20, c: Colors.white),
                        ),
                        Text(
                          'ID ${st.displayId} · Lv ${st.level}',
                          style: ts(12, w: FontWeight.w700, c: Colors.white.withValues(alpha: .9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...staggerAll([for (final t in top) _tile(t)], stepMs: 35, baseMs: 120),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Divider(color: UC.line, height: 1),
            ),
            ...staggerAll([for (final t in bottom) _tile(t)], stepMs: 35, baseMs: 380),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _tile((IconData, String, VoidCallback) t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: GroupedRow(icon: t.$1, title: t.$2, onTap: t.$3),
  );
}

enum LiveListKind { trending, recommended, private, favourite, following }

/// A full screen list of real lives with a header (Trending, Recommended, ...).
class LiveListScreen extends StatefulWidget {
  final LiveListKind kind;
  final bool asTab;
  const LiveListScreen({super.key, required this.kind, this.asTab = false});
  @override
  State<LiveListScreen> createState() => _LiveListScreenState();
}

class _LiveListScreenState extends State<LiveListScreen> {
  final feed = RoomsFeed.I;
  @override
  void initState() {
    super.initState();
    feed.attach();
  }

  @override
  void dispose() {
    feed.detach();
    super.dispose();
  }

  (String, String) get _head => switch (widget.kind) {
    LiveListKind.trending => ('Trending', 'Most watched right now'),
    LiveListKind.recommended => ('Recommended', 'Picked from your interests'),
    LiveListKind.private => ('Best for private', 'Small, cosy lives'),
    LiveListKind.favourite => ('My favourite', 'Hosts you follow'),
    LiveListKind.following => ('Following', 'Hosts you follow'),
  };

  List<LiveRoomInfo> _list(List<LiveRoomInfo> all) {
    final st = AppState.I;
    switch (widget.kind) {
      case LiveListKind.trending:
        return [...all]..sort((a, b) => b.viewers.compareTo(a.viewers));
      case LiveListKind.recommended:
        final hits = all.where((r) => st.interests.any((i) => '${r.tag} ${r.title}'.toLowerCase().contains(i.toLowerCase()))).toList();
        return hits.isEmpty ? all : hits;
      case LiveListKind.private:
        return [...all.where((r) => r.viewers <= 10)]..sort((a, b) => a.viewers.compareTo(b.viewers));
      case LiveListKind.favourite:
      case LiveListKind.following:
        return all.where((r) => st.isFollowing(r.hostId)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final (title, sub) = _head;
    final followKind = widget.kind == LiveListKind.following || widget.kind == LiveListKind.favourite;
    return Scaffold(
      body: AuroraBg(
        child: ListenableBuilder(
          listenable: Listenable.merge([feed, AppState.I]),
          builder: (context, _) {
            final list = _list(feed.others);
            final offline = followKind
                ? AppState.I.following.entries.where((e) => !feed.others.any((r) => r.hostId == e.key)).toList()
                : <MapEntry<String, String>>[];
            return RefreshIndicator(
              color: UC.primary,
              onRefresh: feed.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: LargeTitle(title, eyebrow: sub, back: !widget.asTab),
                  ),
                  if (!feed.loadedOnce && feed.serverConfigured)
                    SliverPadding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 12), sliver: liveGridSkeletonSliver())
                  else if (list.isEmpty && feed.loadedOnce)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: NoLives(
                          serverConfigured: feed.serverConfigured,
                          error: feed.error,
                          emptyText: followKind ? 'Nobody you follow is live.' : 'Nobody is live right now.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 12), sliver: liveGridSliver(list)),
                  if (followKind && offline.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 12, 6),
                        child: Text('Offline now', style: ts(15, w: FontWeight.w800)),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: offline.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: Avatar(name: offline[i].value, size: 42),
                        title: Text(offline[i].value, style: ts(14.5, w: FontWeight.w800)),
                        subtitle: Text(
                          'You will see them here when they go live',
                          style: ts(12, w: FontWeight.w600, c: UC.muted),
                        ),
                        trailing: TextButton(
                          onPressed: () => AppState.I.toggleFollow(offline[i].key, offline[i].value),
                          child: Text(
                            'Unfollow',
                            style: ts(13, w: FontWeight.w800, c: UC.deep),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (followKind && AppState.I.following.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                        child: Text(
                          'Tap + Follow while watching a live, and those hosts will show here.',
                          textAlign: TextAlign.center,
                          style: ts(13, w: FontWeight.w600, c: UC.muted, h: 1.4),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: widget.asTab ? navSpace(context) : pad.bottom + 20)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class WatchHistoryScreen extends StatelessWidget {
  const WatchHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBg(
        child: ListenableBuilder(
          listenable: AppState.I,
          builder: (context, _) {
            final items = AppState.I.watched.map((w) => w.split('|')).where((p) => p.length >= 4).toList();
            return Column(
              children: [
                LargeTitle(
                  'Watch history',
                  actions: [
                    if (items.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          AppState.I.watched.clear();
                          AppState.I.addCoins(0); // saves + notifies
                        },
                        child: Text(
                          'Clear',
                          style: ts(13, w: FontWeight.w800, c: UC.deep),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: items.isEmpty
                      ? const _Empty(Icons.history_rounded, 'Lives you watch will show here.')
                      : ListView(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, pad.bottom + 16),
                          children: staggerAll([
                            for (final p in items)
                              ListTile(
                                leading: Avatar(name: p[1], size: 44),
                                title: Text(p[1], style: ts(14.5, w: FontWeight.w800)),
                                subtitle: Text(
                                  '${p[2].isEmpty ? 'Live' : p[2]} · ${_ago(int.tryParse(p[3]) ?? 0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                ),
                                trailing: _LiveNowButton(hostId: p[0]),
                              ),
                          ]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _ago(int ms) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _LiveNowButton extends StatelessWidget {
  final String hostId;
  const _LiveNowButton({required this.hostId});
  @override
  Widget build(BuildContext context) {
    final r = RoomsFeed.I.others.where((r) => r.hostId == hostId).firstOrNull;
    if (r == null) return const SizedBox.shrink();
    return GestureDetector(onTap: () => openLive(context, r), child: const LiveBadge());
  }
}

class InfoScreen extends StatelessWidget {
  final String title, text;
  final IconData icon;
  const InfoScreen(this.title, this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBg(
        child: Column(
          children: [
            LargeTitle(title),
            Expanded(child: _Empty(icon, text)),
            SizedBox(height: pad.bottom),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StaggerIn(
            index: 0,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [UC.blush, UC.peach], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .18), blurRadius: 30, offset: const Offset(0, 12))],
              ),
              child: Icon(icon, size: 42, color: UC.primary),
            ),
          ),
          const SizedBox(height: 16),
          StaggerIn(
            index: 1,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: ts(16, w: FontWeight.w500, c: UC.muted, h: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}
