import 'dart:math';

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
import 'profile_screen.dart';

/// Home dashboard: greeting, search on top, live stories, categories, a trending
/// carousel, Connect, then every live in a grid. Only real lives from the server.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const _cats = [
  ('All', Icons.apps_rounded, UC.primary),
  ('Following', Icons.favorite_rounded, Color(0xFFE5486F)),
  ('Music', Icons.music_note_rounded, Color(0xFF8E4FA0)),
  ('Gaming', Icons.sports_esports_rounded, Color(0xFF3B6FE0)),
  ('Talk', Icons.forum_rounded, Color(0xFF12A15F)),
  ('Dance', Icons.nightlife_rounded, Color(0xFFF2711C)),
  ('Comedy', Icons.sentiment_very_satisfied_rounded, Color(0xFFD99A00)),
  ('Fitness', Icons.fitness_center_rounded, Color(0xFF0E9C9B)),
  ('Cooking', Icons.restaurant_rounded, Color(0xFFD9485F)),
  ('Study', Icons.menu_book_rounded, Color(0xFF6B4A6E)),
];

class _HomeScreenState extends State<HomeScreen> {
  String cat = 'All';
  bool newest = false;
  final q = TextEditingController();
  final qFocus = FocusNode();
  final feed = RoomsFeed.I;

  @override
  void initState() {
    super.initState();
    feed.attach();
  }

  @override
  void dispose() {
    feed.detach();
    q.dispose();
    qFocus.dispose();
    super.dispose();
  }

  bool _match(LiveRoomInfo r, String t) {
    final s = t.toLowerCase();
    return r.tag.toLowerCase().contains(s) || r.title.toLowerCase().contains(s) || r.hostName.toLowerCase().contains(s);
  }

  List<LiveRoomInfo> _visible(List<LiveRoomInfo> all) {
    var list = switch (cat) {
      'All' => [...all],
      'Following' => all.where((r) => AppState.I.isFollowing(r.hostId)).toList(),
      _ => all.where((r) => _match(r, cat)).toList(),
    };
    final term = q.text.trim();
    if (term.isNotEmpty) list = list.where((r) => _match(r, term)).toList();
    newest ? list.sort((a, b) => b.startedAt.compareTo(a.startedAt)) : list.sort((a, b) => b.viewers.compareTo(a.viewers));
    return list;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : h < 17
        ? 'Good afternoon'
        : 'Good evening';
  }

  void _sortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.paddingOf(c).bottom + 12),
        child: SoftCard(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: UC.line, borderRadius: BorderRadius.circular(9)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Sort lives', style: ds(22)),
              const SizedBox(height: 14),
              SlideSegmented(
                items: const ['Most watched', 'Newest'],
                value: newest ? 'Newest' : 'Most watched',
                onChanged: (v) {
                  setState(() => newest = v == 'Newest');
                  Navigator.pop(c);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return AuroraBg(
      child: ListenableBuilder(
        listenable: Listenable.merge([feed, AppState.I, q]),
        builder: (context, _) {
          final st = AppState.I;
          final all = feed.others;
          final list = _visible(all);
          final searching = q.text.trim().isNotEmpty;
          final trending = ([...all]..sort((a, b) => b.viewers.compareTo(a.viewers))).take(6).toList();
          final loading = !feed.loadedOnce && feed.serverConfigured;
          return RefreshIndicator(
            color: UC.primary,
            edgeOffset: pad.top,
            onRefresh: feed.refresh,
            child: GestureDetector(
              onTap: () => qFocus.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  // top row: menu · coins · bell · me
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, pad.top + 10, 16, 0),
                      child: Row(
                        children: [
                          GlassCircle(Icons.menu_rounded, label: 'Menu', onTap: () => Scaffold.of(context).openDrawer()),
                          const Spacer(),
                          CoinPill(st.coins, onTap: () => Navigator.pushNamed(context, '/coins')),
                          const SizedBox(width: 8),
                          GlassCircle(Icons.notifications_none_rounded, label: 'Notifications', dot: true, onTap: () => Navigator.pushNamed(context, '/inbox')),
                          const SizedBox(width: 8),
                          Pressable(
                            label: 'Your profile',
                            onTap: () => Navigator.push(context, umiRoute((_) => const WithBack(ProfileScreen()))),
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: UC.brandGradient),
                              child: Avatar(name: st.name, img: 'assets/img/me.jpg', size: 41, border: Colors.white, borderW: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...staggerSlivers([
                    // greeting + headline
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Eyebrow('$_greeting, ${st.firstName}${all.isNotEmpty ? ' · ${all.length} live now' : ''}'),
                            const SizedBox(height: 8),
                            const HeroTitle('Find your ', 'vibe', size: 40),
                          ],
                        ),
                      ),
                    ),
                    // search
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: SearchPill(controller: q, focus: qFocus, hint: 'Search hosts, topics, lives…', onFilter: _sortSheet, filterOn: newest),
                      ),
                    ),
                    // live stories
                    if (!searching)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 112,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
                            children: [
                              _story(
                                label: 'Go live',
                                onTap: () => Navigator.pushNamed(context, '/golive'),
                                child: Container(
                                  color: Colors.white,
                                  child: const Icon(Icons.add_rounded, color: UC.primary, size: 30),
                                ),
                              ),
                              if (loading) const StoriesSkeleton(),
                              for (final r in all)
                                _story(
                                  label: r.hostName,
                                  live: true,
                                  onTap: () => openLive(context, r),
                                  child: Container(
                                    decoration: BoxDecoration(gradient: hostGradient(r.hostId)),
                                    alignment: Alignment.center,
                                    child: Text(r.hostName.isEmpty ? '?' : r.hostName.characters.first.toUpperCase(), style: ds(26, c: Colors.white)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    // categories
                    SliverToBoxAdapter(
                      child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: SectionHead(searching ? 'Filter' : 'Categories')),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 104,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _cats.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 4),
                          itemBuilder: (_, i) {
                            final (name, icon, tint) = _cats[i];
                            return CategoryBubble(label: name, icon: icon, tint: tint, selected: cat == name, onTap: () => setState(() => cat = name));
                          },
                        ),
                      ),
                    ),
                    // trending carousel
                    if (!searching && cat == 'All' && trending.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                          child: SectionHead('Trending now', sub: 'The most watched lives right now'),
                        ),
                      ),
                      SliverToBoxAdapter(child: _Carousel(trending)),
                    ],
                    // Connect
                    if (!searching && cat == 'All')
                      SliverToBoxAdapter(
                        child: Padding(padding: const EdgeInsets.fromLTRB(16, 22, 16, 0), child: _connect(all)),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                        child: SectionHead(
                          searching ? 'Results' : (cat == 'All' ? 'Live now' : cat),
                          sub: searching
                              ? '${list.length} ${list.length == 1 ? 'live matches' : 'lives match'} “${q.text.trim()}”'
                              : (newest ? 'Newest first' : 'Most watched first'),
                          trailing: feed.loading
                              ? const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: UC.primary)),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ]),
                  if (loading)
                    SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), sliver: liveGridSkeletonSliver())
                  else if (list.isEmpty && feed.loadedOnce)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: NoLives(
                          serverConfigured: feed.serverConfigured,
                          error: feed.error,
                          emptyText: searching
                              ? 'No lives match “${q.text.trim()}”.'
                              : cat == 'Following'
                              ? 'Nobody you follow is live.'
                              : cat != 'All'
                              ? 'No $cat lives right now.'
                              : 'Nobody is live right now.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), sliver: liveGridSliver(list)),
                  SliverToBoxAdapter(child: SizedBox(height: navSpace(context))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _story({required String label, required Widget child, bool live = false, VoidCallback? onTap}) => Pressable(
    onTap: onTap,
    label: label,
    child: Container(
      width: 72,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: live ? const SweepGradient(colors: [UC.primary, UC.accent, UC.gold, UC.primary]) : null,
              color: live ? null : Colors.white,
              boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .10), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(child: child),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ts(12.5, w: FontWeight.w700, c: UC.ink),
          ),
        ],
      ),
    ),
  );

  Widget _connect(List<LiveRoomInfo> all) => SoftCard(
    padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
    onTap: () {
      if (all.isEmpty) {
        toast(context, feed.serverConfigured ? 'Nobody is live right now. Try again soon!' : 'Add your live server first.');
        return;
      }
      openLive(context, all[Random().nextInt(all.length)]);
    },
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Random match'),
              const SizedBox(height: 6),
              const HeroTitle('Meet someone ', 'new', size: 25),
              const SizedBox(height: 12),
              Container(
                height: 38,
                padding: const EdgeInsets.only(left: 6, right: 14),
                decoration: BoxDecoration(color: UC.ink, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                      child: const Icon(Icons.shuffle_rounded, size: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connect',
                      style: ts(14, w: FontWeight.w800, c: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 124,
          height: 100,
          child: Stack(
            children: [
              Positioned(left: 4, top: 0, child: _bubble('assets/img/priya.jpg', 54)),
              Positioned(right: 0, top: 6, child: _bubble('assets/img/rahul.jpg', 46)),
              Positioned(left: 34, bottom: 0, child: _bubble('assets/img/zara.jpg', 48)),
              Positioned(right: 16, bottom: 8, child: _bubble('assets/img/kabir.jpg', 34)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _bubble(String img, double s) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: UC.inkA(.15), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Avatar(img: img, size: s, border: Colors.white, borderW: 2.5),
  );
}

/// Big swipeable cards; the centred one is full size, its neighbours shrink a little.
class _Carousel extends StatefulWidget {
  final List<LiveRoomInfo> rooms;
  const _Carousel(this.rooms);
  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final pc = PageController(viewportFraction: .8);

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 380,
    child: PageView.builder(
      controller: pc,
      padEnds: false,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.rooms.length,
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: pc,
        builder: (_, child) {
          final page = pc.hasClients && pc.position.haveDimensions ? (pc.page ?? 0) : 0.0;
          final d = (page - i).abs().clamp(0.0, 1.0);
          return Transform.scale(scale: 1 - d * .07, alignment: Alignment.centerLeft, child: child);
        },
        child: Padding(
          padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6),
          child: FeatureLiveCard(widget.rooms[i]),
        ),
      ),
    ),
  );
}
