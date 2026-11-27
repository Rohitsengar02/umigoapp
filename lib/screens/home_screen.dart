import 'package:material_ui/material_ui.dart';

import '../live/rooms_feed.dart';
import '../live/token_api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_cards.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import '../data/social_data.dart' show Category, allCategories;

/// Home, kept slim: top bar, search, then three tabs.
/// Feed = every live, Categories = all categories, New = newest lives.
/// Real lives from the server come first (with camera thumbnails), demo lives after them.
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
    // real lives first (with their camera thumbnails), then demo lives
    list.sort((a, b) {
      final d = (a.demoId == null ? 0 : 1) - (b.demoId == null ? 0 : 1);
      if (d != 0) return d;
      return byNew ? b.startedAt.compareTo(a.startedAt) : b.viewers.compareTo(a.viewers);
    });
    return list;
  }

  /// Lives in a category right now: the demo count plus real lives tagged with it.
  int _catCount(Category c, List<LiveRoomInfo> real) => c.lives + real.where((r) => r.tag.toLowerCase() == c.name.toLowerCase()).length;

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
          final cats = allCategories
              .where((c) => !searching || c.name.toLowerCase().contains(term.toLowerCase()) || c.blurb.toLowerCase().contains(term.toLowerCase()))
              .toList();
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
                    // search
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: SearchPill(
                          controller: q,
                          focus: qFocus,
                          hint: tab == 'Categories' ? 'Search categories…' : 'Search hosts, topics, lives…',
                          onFilter: _sortSheet,
                          filterOn: newest,
                        ),
                      ),
                    ),
                    // Feed · Categories · New
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: SlideSegmented(items: _tabs, value: tab, height: 44, onChanged: (v) => setState(() => tab = v)),
                      ),
                    ),
                  ]),
                  ...switch (tab) {
                    'Categories' => _categoriesTab(cats, real),
                    'New' => _livesTab(list, newTab: true, searching: searching),
                    _ => _livesTab(list, newTab: false, searching: searching),
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

  /// Every live as a slim grid (5px gaps, light corners). Real lives come first.
  /// In the New tab the newest come first and show when they started.
  List<Widget> _livesTab(List<LiveRoomInfo> list, {required bool newTab, required bool searching}) {
    final term = q.text.trim();
    return [
      if (searching)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
            child: Text(
              '${list.length} ${list.length == 1 ? 'live matches' : 'lives match'} “$term”',
              style: ts(13, w: FontWeight.w600, c: UC.muted),
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
          padding: const EdgeInsets.symmetric(horizontal: 5),
          sliver: liveGridSliver(list, showAge: newTab, gap: 5, radius: 12),
        ),
    ];
  }

  /// Every category as a bento of photo tiles; a tap opens its lives.
  List<Widget> _categoriesTab(List<Category> cats, List<LiveRoomInfo> real) => [
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
}
