import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart' show fmtK;
import '../data/social_data.dart';
import '../live/rooms_feed.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_cards.dart';
import '../widgets/motion.dart';
import '../widgets/pay_sheet.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui.dart';
import 'creator_profile_screen.dart';
import 'reels_screen.dart';

/// Every category as a bento grid, with a region filter on top.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String region = 'All India';
  final q = TextEditingController();

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  int _count(Category c) => region == 'All India' ? c.lives : (c.lives * (0.12 + (region.hashCode ^ c.name.hashCode).abs() % 20 / 100)).round();

  @override
  Widget build(BuildContext context) {
    final s = q.text.trim().toLowerCase();
    final list = allCategories.where((c) => s.isEmpty || c.name.toLowerCase().contains(s) || c.blurb.toLowerCase().contains(s)).toList();
    final total = list.fold<int>(0, (a, c) => a + _count(c));
    return Scaffold(
      body: AuroraBg(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ...staggerSlivers([
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 0),
                  child: Row(
                    children: [
                      GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
                      const Spacer(),
                      GlassCircle(Icons.play_circle_rounded, label: 'Reels', size: 42, onTap: () => openReels(context, reels, 0)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Eyebrow('${fmtK(total)} lives · $region'), const SizedBox(height: 6), const HeroTitle('Explore ', 'categories', size: 36)],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SearchPill(controller: q, hint: 'Search categories', onChanged: (_) => setState(() {})),
                ),
              ),
              // regions, like the "Regional" screen in the plan
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 62,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    children: [
                      for (final r in regions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChipX(r, on: r == region, onTap: () => setState(() => region = r)),
                        ),
                    ],
                  ),
                ),
              ),
            ]),
            if (list.isEmpty)
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                sliver: SliverList.list(children: _bento(list)),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                child: SectionHead('Top creators', sub: region == 'All India' ? 'Across India' : 'In $region'),
              ),
            ),
            SliverToBoxAdapter(child: _CreatorStrip(region: region)),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 30)),
          ],
        ),
      ),
    );
  }

  /// One big tile, then pairs, repeating: a calm rhythm instead of a flat grid.
  List<Widget> _bento(List<Category> list) {
    final out = <Widget>[];
    var i = 0, row = 0;
    while (i < list.length) {
      if (row % 3 == 0) {
        out.add(
          StaggerIn(
            index: row,
            child: _Tile(list[i], count: _count(list[i]), region: region, height: 190, big: true),
          ),
        );
        i++;
      } else {
        final a = list[i], b = i + 1 < list.length ? list[i + 1] : null;
        out.add(
          StaggerIn(
            index: row,
            child: Row(
              children: [
                Expanded(
                  child: _Tile(a, count: _count(a), region: region, height: 170),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: b == null ? const SizedBox() : _Tile(b, count: _count(b), region: region, height: 170),
                ),
              ],
            ),
          ),
        );
        i += 2;
      }
      out.add(const SizedBox(height: 12));
      row++;
    }
    return out;
  }
}

class _Tile extends StatelessWidget {
  final Category c;
  final int count;
  final String region;
  final double height;
  final bool big;
  const _Tile(this.c, {required this.count, required this.region, required this.height, this.big = false});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => Navigator.push(context, umiRoute((_) => CategoryDetailScreen(category: c, region: region))),
    scale: .97,
    label: c.name,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: c.tint.withValues(alpha: .28), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(tag: 'cat_${c.name}', child: fadeInAsset(c.img)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.tint.withValues(alpha: .15), c.tint.withValues(alpha: .55), c.tint.withValues(alpha: .95)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), shape: BoxShape.circle),
              child: Icon(c.icon, color: c.tint, size: 21),
            ),
          ),
          Positioned(right: 12, top: 14, child: DarkChip('${fmtK(count)} live', icon: Icons.sensors_rounded)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: ds(big ? 30 : 22, c: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  c.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(big ? 13.5 : 12, w: FontWeight.w600, c: Colors.white.withValues(alpha: .9)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CreatorStrip extends StatelessWidget {
  final String region;
  const _CreatorStrip({required this.region});
  @override
  Widget build(BuildContext context) {
    var list = creators.where((c) => region == 'All India' || c.region == region).toList();
    if (list.isEmpty) list = creators;
    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => CreatorCard(list[i]),
      ),
    );
  }
}

/// Compact creator card: photo, live ring, name, followers, Follow.
class CreatorCard extends StatelessWidget {
  final Creator c;
  const CreatorCard(this.c, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.I,
    builder: (context, _) {
      final f = AppState.I.isFollowing(c.id);
      return Pressable(
        onTap: () => openCreator(context, c.id),
        label: c.name,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: softBox(26),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: c.live ? const SweepGradient(colors: [UC.primary, UC.accent, UC.gold, UC.primary]) : null,
                ),
                child: Avatar(img: c.img, size: 66, border: Colors.white, borderW: 2.5),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      c.name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(14.5, w: FontWeight.w800),
                    ),
                  ),
                  if (c.verified) ...[const SizedBox(width: 3), const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF3B8BFF))],
                ],
              ),
              Text(
                '${fmtK(c.followers)} fans · ${c.cat}',
                maxLines: 1,
                style: ts(11.5, w: FontWeight.w600, c: UC.muted),
              ),
              const Spacer(),
              Pressable(
                onTap: () => AppState.I.toggleFollow(c.id, c.name),
                label: f ? 'Unfollow' : 'Follow',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: f ? UC.surface : UC.ink, borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    f ? 'Following' : 'Follow',
                    style: ts(13, w: FontWeight.w800, c: f ? UC.ink : Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// One category: lives, reels and creators, filtered by region.
class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final String region;
  const CategoryDetailScreen({super.key, required this.category, this.region = 'All India'});
  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String tab = 'Live';
  late String region = widget.region;
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

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final pad = MediaQuery.paddingOf(context);
    final catReels = reels.where((r) => r.cat == c.name).toList();
    final shownReels = catReels.isEmpty ? reels : catReels;
    final catCreators = creators.where((x) => x.cat == c.name && (region == 'All India' || x.region == region)).toList();
    return Scaffold(
      body: AuroraBg(
        child: ListenableBuilder(
          listenable: feed,
          builder: (context, _) {
            final lives = feed.others.where((r) => r.tag.toLowerCase() == c.name.toLowerCase() || (c.name == 'Talk' && r.tag == 'Chat')).toList();
            final liveCreators = creators.where((x) => x.cat == c.name && x.live).toList();
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300 + pad.top,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(tag: 'cat_${c.name}', child: fadeInAsset(c.img)),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: .25), c.tint.withValues(alpha: .55), UC.bg],
                              stops: const [0, .6, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: pad.top + 8,
                          left: 16,
                          child: GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(c.icon, color: c.tint, size: 26),
                              ),
                              const SizedBox(height: 10),
                              Text(c.name, style: ds(40, c: UC.ink)),
                              Text(
                                '${fmtK(c.lives)} live now · ${c.blurb}',
                                style: ts(14, w: FontWeight.w600, c: UC.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                      children: [
                        for (final r in regions)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChipX(r, on: r == region, onTap: () => setState(() => region = r)),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: SlideSegmented(items: const ['Live', 'Reels', 'Creators'], value: tab, onChanged: (v) => setState(() => tab = v)),
                  ),
                ),
                if (tab == 'Live') ...[
                  if (lives.isNotEmpty)
                    SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: liveGridSliver(lives))
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: NoLives(serverConfigured: feed.serverConfigured, error: feed.error, emptyText: 'No ${c.name} lives on the server right now.'),
                      ),
                    ),
                  if (liveCreators.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: SectionHead('Usually live', sub: 'Their schedules, so you never miss one'),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: liveCreators.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => CreatorRow(liveCreators[i]),
                      ),
                    ),
                  ],
                ],
                if (tab == 'Reels')
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: .62,
                      ),
                      itemCount: shownReels.length,
                      itemBuilder: (_, i) => ReelThumb(shownReels[i], onTap: () => openReels(context, shownReels, i)),
                    ),
                  ),
                if (tab == 'Creators')
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: catCreators.isEmpty
                        ? SliverToBoxAdapter(
                            child: SoftCard(
                              child: Text(
                                'No ${c.name} creators in $region yet.',
                                textAlign: TextAlign.center,
                                style: ts(14.5, w: FontWeight.w700, c: UC.muted),
                              ),
                            ),
                          )
                        : SliverList.separated(
                            itemCount: catCreators.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => CreatorRow(catCreators[i]),
                          ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: pad.bottom + 30)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A creator as a row: avatar, name, schedule, access, Follow.
class CreatorRow extends StatelessWidget {
  final Creator c;
  const CreatorRow(this.c, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.I,
    builder: (context, _) {
      final f = AppState.I.isFollowing(c.id);
      return SoftCard(
        onTap: () => openCreator(context, c.id),
        padding: const EdgeInsets.all(12),
        radius: 24,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: c.live ? const SweepGradient(colors: [UC.primary, UC.accent, UC.gold, UC.primary]) : null,
              ),
              child: Avatar(img: c.img, size: 52, border: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(15, w: FontWeight.w800),
                        ),
                      ),
                      if (c.verified) ...[const SizedBox(width: 3), const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF3B8BFF))],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: c.live ? UC.primary : UC.muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          c.live ? 'Live now' : '${c.liveDays} · ${c.liveTime}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(12.5, w: FontWeight.w700, c: c.live ? UC.primary : UC.muted),
                        ),
                      ),
                      if (c.access != LiveAccess.public) ...[
                        const SizedBox(width: 6),
                        Icon(c.access == LiveAccess.paid ? Icons.lock_rounded : Icons.workspace_premium_rounded, size: 13, color: accessColor(c.access)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Pressable(
              onTap: () => AppState.I.toggleFollow(c.id, c.name),
              label: f ? 'Unfollow' : 'Follow',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: f ? UC.surface : null, gradient: f ? null : UC.brandGradient, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  f ? 'Following' : 'Follow',
                  style: ts(13, w: FontWeight.w800, c: f ? UC.ink : Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
