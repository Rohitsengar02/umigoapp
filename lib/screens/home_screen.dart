import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../live/rooms_feed.dart';
import '../live/token_api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_cards.dart';
import '../widgets/motion.dart';
import 'profile_screen.dart';

/// Home, laid out from Rohit's sketch: menu + Umigo + coins / bell / profile,
/// stories, Connect card, Feed / Categories / New tabs, filter chips and a
/// 2-column grid of real lives from your server (no demo rooms).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const _tabs = ['Feed', 'Categories', 'New'];
const _baseChips = ['All', 'Following', 'Music', 'Gaming', 'Talk', 'Dance'];
const _categories = [
  ('Music', Icons.music_note_rounded),
  ('Gaming', Icons.sports_esports_rounded),
  ('Talk', Icons.forum_rounded),
  ('Dance', Icons.nightlife_rounded),
  ('Comedy', Icons.sentiment_very_satisfied_rounded),
  ('Fitness', Icons.fitness_center_rounded),
  ('Cooking', Icons.restaurant_rounded),
  ('Study', Icons.menu_book_rounded),
];

class _HomeScreenState extends State<HomeScreen> {
  String tab = 'Feed';
  String chip = 'All';
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

  bool _tagIs(LiveRoomInfo r, String t) => r.tag.toLowerCase().contains(t.toLowerCase()) || r.title.toLowerCase().contains(t.toLowerCase());

  List<LiveRoomInfo> _visible(List<LiveRoomInfo> all) {
    if (tab == 'New') {
      return [...all]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    }
    return switch (chip) {
      'All' => [...all]..sort((a, b) => b.viewers.compareTo(a.viewers)),
      'Following' => all.where((r) => AppState.I.isFollowing(r.hostId)).toList(),
      _ => all.where((r) => _tagIs(r, chip)).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: Listenable.merge([feed, AppState.I]),
      builder: (context, _) {
        final st = AppState.I;
        final all = feed.others;
        final list = _visible(all);
        return RefreshIndicator(
          color: UC.primary,
          onRefresh: feed.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // top bar: menu, Umigo, coins, bell, profile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4, pad.top + 6, 12, 4),
                  child: Row(
                    children: [
                      IconButton(tooltip: 'Menu', onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu_rounded, size: 26)),
                      Text('Umigo', style: ds(26)),
                      const Spacer(),
                      CoinPill(st.coins, onTap: () => Navigator.pushNamed(context, '/coins')),
                      const SizedBox(width: 6),
                      _roundIcon(Icons.notifications_none_rounded, 'Notifications', () => Navigator.pushNamed(context, '/inbox'), dot: true),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.push(context, umiRoute((_) => const WithBack(ProfileScreen()))),
                        child: Avatar(name: st.name, img: 'assets/img/me.jpg', size: 38, border: UC.primary),
                      ),
                    ],
                  ),
                ),
              ),
              // stories: your story + everyone live now
              SliverToBoxAdapter(
                child: StaggerIn(
                  index: 0,
                  child: SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      children: [
                        _story(
                          label: 'Your story',
                          onTap: () => Navigator.pushNamed(context, '/golive'),
                          child: Stack(
                            children: [
                              Avatar(name: st.name, img: 'assets/img/me.jpg', size: 62),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: UC.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final r in all)
                          _story(
                            label: r.hostName,
                            live: true,
                            onTap: () => openLive(context, r),
                            child: Container(
                              decoration: BoxDecoration(gradient: hostGradient(r.hostId), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(r.hostName.isEmpty ? '?' : r.hostName.characters.first.toUpperCase(), style: ds(24, c: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Connect: meet new people
              SliverToBoxAdapter(
                child: StaggerIn(
                  index: 1,
                  child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: _connect(all)),
                ),
              ),
              // Feed / Categories / New
              SliverToBoxAdapter(
                child: StaggerIn(
                  index: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
                    child: Row(
                      children: [
                        for (final t in _tabs)
                          GestureDetector(
                            onTap: () => setState(() => tab = t),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 180),
                                    style: t == tab ? ds(21, c: UC.ink) : ds(17, c: UC.muted, w: FontWeight.w700),
                                    child: Text(t),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    height: 3,
                                    width: t == tab ? 26 : 0,
                                    decoration: BoxDecoration(color: UC.primary, borderRadius: BorderRadius.circular(3)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (feed.loading) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: UC.primary)),
                      ],
                    ),
                  ),
                ),
              ),
              if (tab == 'Feed')
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      children: [
                        for (final k in _baseChips)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => chip = k),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: k == chip ? UC.ink : Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: k == chip ? UC.ink : UC.line, width: 1.5),
                                ),
                                child: Text(
                                  k,
                                  style: ts(13, w: FontWeight.w800, c: k == chip ? Colors.white : UC.ink),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (tab == 'Categories')
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 84,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final (name, icon) = _categories[i];
                      final n = all.where((r) => _tagIs(r, name)).length;
                      return StaggerIn(
                        index: i,
                        stepMs: 40,
                        baseMs: 0,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            tab = 'Feed';
                            chip = _baseChips.contains(name) ? name : 'All';
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(gradient: hostGradient(name), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Icon(icon, color: Colors.white, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: ds(18, c: Colors.white)),
                                      Text(
                                        n == 0 ? 'No lives yet' : '$n live now',
                                        style: ts(12, w: FontWeight.w700, c: Colors.white.withValues(alpha: .85)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else if (list.isEmpty && feed.loadedOnce)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    child: NoLives(
                      serverConfigured: feed.serverConfigured,
                      error: feed.error,
                      emptyText: chip == 'Following' && tab == 'Feed'
                          ? 'Nobody you follow is live.'
                          : chip != 'All' && tab == 'Feed'
                          ? 'No $chip lives right now.'
                          : 'Nobody is live right now.',
                    ),
                  ),
                )
              else
                SliverPadding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 20), sliver: liveGridSliver(list)),
            ],
          ),
        );
      },
    );
  }

  Widget _roundIcon(IconData icon, String tip, VoidCallback onTap, {bool dot = false}) => Stack(
    children: [
      Material(
        color: UC.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tip,
            child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 21)),
          ),
        ),
      ),
      if (dot)
        Positioned(
          top: 8,
          right: 9,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: UC.primary,
              shape: BoxShape.circle,
              border: Border.all(color: UC.surface, width: 2),
            ),
          ),
        ),
    ],
  );

  Widget _story({required String label, required Widget child, bool live = false, VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 66,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: live ? UC.brandGradient : null),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(child: child),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ts(11.5, w: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _connect(List<LiveRoomInfo> all) => GestureDetector(
    onTap: () {
      if (all.isEmpty) {
        toast(context, feed.serverConfigured ? 'Nobody is live right now. Try again soon!' : 'Add your live server first.');
        return;
      }
      openLive(context, all[Random().nextInt(all.length)]);
    },
    child: Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [UC.soft, UC.accentSoft]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: UC.line, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connect', style: ds(26, c: UC.ink)),
                const SizedBox(height: 2),
                Text(
                  'Meet new people',
                  style: ts(13.5, w: FontWeight.w700, c: UC.muted),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: UC.primary, borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start',
                        style: ts(12.5, w: FontWeight.w800, c: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            height: 90,
            child: Stack(
              children: [
                Positioned(left: 4, top: 0, child: _bubble('assets/img/priya.jpg', 50)),
                Positioned(right: 2, top: 4, child: _bubble('assets/img/rahul.jpg', 44)),
                Positioned(left: 30, bottom: 0, child: _bubble('assets/img/zara.jpg', 46)),
                Positioned(right: 18, bottom: 6, child: _bubble('assets/img/kabir.jpg', 34)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _bubble(String img, double s) => Avatar(img: img, size: s, border: Colors.white, borderW: 2.5);
}
