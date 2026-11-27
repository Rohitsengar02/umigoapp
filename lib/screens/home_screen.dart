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
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'reels_screen.dart';
import '../data/social_data.dart' show Category, allCategories, creators, reels;

/// Home: greeting, search, a "Live now" row of thumbnails, then three tabs.
/// Feed = trending + every live, Categories = all categories, New = newest lives.
/// Real lives from the server come first, demo lives after them.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const _tabs = ['Feed', 'Categories', 'New'];

class _HomeScreenState extends State<HomeScreen> {
  String tab = 'Feed';
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

  List<LiveRoomInfo> _visible(List<LiveRoomInfo> all, {required bool byNew}) {
    var list = [...all];
    final term = q.text.trim();
    if (term.isNotEmpty) list = list.where((r) => _match(r, term)).toList();
    byNew ? list.sort((a, b) => b.startedAt.compareTo(a.startedAt)) : list.sort((a, b) => b.viewers.compareTo(a.viewers));
    return list;
  }

  /// Lives in a category right now: the demo count plus real lives tagged with it.
  int _catCount(Category c, List<LiveRoomInfo> real) => c.lives + real.where((r) => r.tag.toLowerCase() == c.name.toLowerCase()).length;

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
          final real = feed.others;
          final all = feed.withDemo;
          final term = q.text.trim();
          final searching = term.isNotEmpty;
          final isNew = tab == 'New';
          final list = _visible(all, byNew: isNew || newest);
          // real lives lead the row (newest snapshot thumbnails), demo lives follow
          int byViewers(LiveRoomInfo a, LiveRoomInfo b) => b.viewers.compareTo(a.viewers);
          final onTop = [
            ...([...real]..sort(byViewers)),
            ...(all.where((r) => r.demoId != null).toList()..sort(byViewers)),
          ];
          final trending = ([...all]..sort(byViewers)).take(6).toList();
          final cats = allCategories
              .where((c) => !searching || c.name.toLowerCase().contains(term.toLowerCase()) || c.blurb.toLowerCase().contains(term.toLowerCase()))
              .toList();
          final loading = !feed.loadedOnce && feed.serverConfigured && all.isEmpty;
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
                        child: SearchPill(
                          controller: q,
                          focus: qFocus,
                          hint: tab == 'Categories' ? 'Search categories…' : 'Search hosts, topics, lives…',
                          onFilter: _sortSheet,
                          filterOn: newest,
                        ),
                      ),
                    ),
                    // whoever is live, on top, with a thumbnail from their live
                    if (!searching && (loading || onTop.isNotEmpty)) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          child: SectionHead(
                            'Live now',
                            sub: '${onTop.length} ${onTop.length == 1 ? 'person is' : 'people are'} live',
                            trailing: feed.loading
                                ? const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: UC.primary)),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: loading
                            ? const SizedBox(
                                height: 112,
                                child: Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: StoriesSkeleton()),
                              )
                            : LiveNowStrip(onTop),
                      ),
                    ],
                    // Feed · Categories · New
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: SlideSegmented(items: _tabs, value: tab, height: 48, onChanged: (v) => setState(() => tab = v)),
                      ),
                    ),
                  ]),
                  ...switch (tab) {
                    'Categories' => _categoriesTab(cats, real),
                    'New' => _livesTab(list, newTab: true, searching: searching),
                    _ => _feedTab(list, trending, searching: searching),
                  },
                  SliverToBoxAdapter(child: SizedBox(height: navSpace(context))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Feed: trending carousel, creators, Connect, then every live.
  List<Widget> _feedTab(List<LiveRoomInfo> list, List<LiveRoomInfo> trending, {required bool searching}) => [
    ...staggerSlivers([
      if (!searching && trending.isNotEmpty) ...[
        SliverToBoxAdapter(
          key: const ValueKey('feed-trend-h'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            child: SectionHead('Trending now', sub: 'The most watched lives right now'),
          ),
        ),
        SliverToBoxAdapter(key: const ValueKey('feed-trend'), child: _Carousel(trending)),
      ],
      if (!searching) ...[
        SliverToBoxAdapter(
          key: const ValueKey('feed-creators-h'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: SectionHead(
              'Creators for you',
              sub: 'Follow to get a ping when they go live',
              action: 'Reels',
              onAction: () => openReels(context, reels, 0),
            ),
          ),
        ),
        SliverToBoxAdapter(
          key: const ValueKey('feed-creators'),
          child: SizedBox(
            height: 206,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: creators.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => CreatorCard(creators[i]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          key: const ValueKey('feed-connect'),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 22, 16, 0), child: _connect(list)),
        ),
      ],
    ]),
    ..._livesTab(list, newTab: false, searching: searching),
  ];

  /// Every live as a grid. In the New tab the newest come first and show when they started.
  List<Widget> _livesTab(List<LiveRoomInfo> list, {required bool newTab, required bool searching}) {
    final term = q.text.trim();
    return [
      SliverToBoxAdapter(
        key: ValueKey('lives-h-$newTab'),
        child: StaggerIn(
          index: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, newTab ? 22 : 26, 20, 12),
            child: SectionHead(
              searching ? 'Results' : (newTab ? 'Just started' : 'All lives'),
              sub: searching
                  ? '${list.length} ${list.length == 1 ? 'live matches' : 'lives match'} “$term”'
                  : newTab
                  ? 'Newest lives first. Be one of the first to join'
                  : (newest ? 'Newest first' : 'Most watched first'),
            ),
          ),
        ),
      ),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NoLives(
              serverConfigured: feed.serverConfigured,
              error: feed.error,
              emptyText: searching ? 'No lives match “$term”.' : 'Nobody is live right now.',
            ),
          ),
        )
      else
        SliverPadding(
          key: ValueKey('lives-$newTab'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: liveGridSliver(list, showAge: newTab),
        ),
    ];
  }

  /// Every category as a bento of photo tiles; a tap opens its lives.
  List<Widget> _categoriesTab(List<Category> cats, List<LiveRoomInfo> real) => [
    SliverToBoxAdapter(
      key: const ValueKey('cats-h'),
      child: StaggerIn(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: SectionHead(
            'All categories',
            sub: '${cats.length} categories',
            action: 'Regions',
            onAction: () => Navigator.push(context, umiRoute((_) => const CategoriesScreen())),
          ),
        ),
      ),
    ),
    if (cats.isEmpty)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No category called “${q.text.trim()}”',
            textAlign: TextAlign.center,
            style: ts(15, w: FontWeight.w700, c: UC.muted),
          ),
        ),
      )
    else
      SliverPadding(
        key: const ValueKey('cats'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.list(children: categoryBento(cats, count: (c) => _catCount(c, real))),
      ),
  ];

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
                decoration: BoxDecoration(color: UC.pill, borderRadius: BorderRadius.circular(99)),
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
