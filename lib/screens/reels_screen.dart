import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../data/social_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gift_icons.dart';
import '../widgets/motion.dart';
import '../widgets/pay_sheet.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui.dart';
import 'creator_profile_screen.dart';
import 'live_viewer_screen.dart';

void openReels(BuildContext context, List<Reel> list, int start) =>
    Navigator.push(context, umiRoute((_) => ReelsScreen(list: list, start: start, pushed: true)));

/// Full-screen vertical reels. Photo reels with a slow Ken Burns move for now;
/// real video plugs in here once uploads go to R2 (see the system design).
class ReelsScreen extends StatefulWidget {
  final List<Reel>? list;
  final int start;
  final bool pushed;
  const ReelsScreen({super.key, this.list, this.start = 0, this.pushed = false});
  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final PageController pc = PageController(initialPage: widget.start);
  late int page = widget.start;
  String feed = 'For you';

  List<Reel> get items {
    if (widget.list != null) return widget.list!;
    if (feed == 'Following') return reels.where((r) => AppState.I.isFollowing(r.creatorId)).toList();
    return reels;
  }

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final list = items;
          return Stack(
            children: [
              if (list.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 44),
                        const SizedBox(height: 12),
                        Text(
                          'Follow creators to fill this feed',
                          textAlign: TextAlign.center,
                          style: ds(24, c: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(width: 200, child: PrimaryButton('See For you', onTap: () => setState(() => feed = 'For you'), height: 48)),
                      ],
                    ),
                  ),
                )
              else
                PageView.builder(
                  key: ValueKey(feed),
                  controller: pc,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => page = i);
                  },
                  itemBuilder: (_, i) => _ReelPage(reel: list[i], active: i == page, bottom: widget.pushed ? pad.bottom + 14 : navSpace(context) - 10),
                ),
              // top bar
              Positioned(
                top: pad.top + 8,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    if (widget.pushed)
                      _RoundDark(Icons.arrow_back_ios_new_rounded, label: 'Back', onTap: () => Navigator.maybePop(context))
                    else
                      const SizedBox(width: 44),
                    const Spacer(),
                    if (widget.list == null)
                      for (final f in ['Following', 'For you'])
                        GestureDetector(
                          onTap: () => setState(() {
                            feed = f;
                            page = 0;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: ts(
                                    16.5,
                                    w: FontWeight.w800,
                                    c: Colors.white.withValues(alpha: f == feed ? 1 : .6),
                                  ),
                                  child: Text(f),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutBack,
                                  width: f == feed ? 22 : 0,
                                  height: 3,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                                ),
                              ],
                            ),
                          ),
                        )
                    else
                      Text(
                        'Reels',
                        style: ts(17, w: FontWeight.w800, c: Colors.white),
                      ),
                    const Spacer(),
                    _RoundDark(Icons.photo_camera_rounded, label: 'Create a reel', onTap: () => toast(context, 'Reel uploads arrive with the backend')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoundDark extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundDark(this.icon, {required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    child: Glass(
      tint: const Color(0x33000000),
      shadow: false,
      radius: BorderRadius.circular(99),
      child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 20)),
    ),
  );
}

class _ReelPage extends StatefulWidget {
  final Reel reel;
  final bool active;
  final double bottom;
  const _ReelPage({required this.reel, required this.active, required this.bottom});
  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> with TickerProviderStateMixin {
  late final AnimationController kb = AnimationController(vsync: this, duration: const Duration(seconds: 14));
  late final AnimationController prog = AnimationController(vsync: this, duration: const Duration(seconds: 15));
  late final AnimationController disc = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  bool paused = false, expanded = false;
  final bursts = <(Offset, int)>[];
  int _burstId = 0;
  int extraComments = 0;

  Reel get r => widget.reel;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _sync();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelPage old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active && !paused && !reduceMotion(context)) {
      kb.repeat(reverse: true);
      prog.repeat();
      disc.repeat();
    } else if (widget.active && !paused) {
      prog.repeat();
    } else {
      kb.stop();
      prog.stop();
      disc.stop();
    }
    if (!widget.active) {
      prog.value = 0;
      paused = false;
    }
  }

  @override
  void dispose() {
    kb.dispose();
    prog.dispose();
    disc.dispose();
    super.dispose();
  }

  void _like({Offset? at}) {
    final st = AppState.I;
    if (at != null) {
      final id = _burstId++;
      setState(() => bursts.add((at, id)));
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => bursts.removeWhere((b) => b.$2 == id));
      });
      if (st.likedReels.contains(r.id)) return;
    }
    HapticFeedback.lightImpact();
    st.toggleIn(st.likedReels, r.id);
  }

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    final c = r.creator;
    final liked = st.likedReels.contains(r.id);
    final saved = st.savedReels.contains(r.id);
    final following = st.isFollowing(c.id);
    return GestureDetector(
      onTap: () => setState(() {
        paused = !paused;
        _sync();
      }),
      onDoubleTapDown: (d) => _like(at: d.localPosition),
      onDoubleTap: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          // photo with a slow Ken Burns drift
          AnimatedBuilder(
            animation: kb,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(kb.value);
              return Transform.scale(scale: 1.04 + t * .12, alignment: Alignment(-.3 + t * .6, r.focusY), child: child);
            },
            child: fadeInAsset(r.img),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
                stops: [0, .2, .55, 1],
              ),
            ),
          ),
          // pause glyph
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: paused ? 1 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: paused ? 1 : .6,
                child: Icon(Icons.play_arrow_rounded, size: 84, color: Colors.white.withValues(alpha: .85)),
              ),
            ),
          ),
          for (final b in bursts) _HeartBurst(key: ValueKey(b.$2), at: b.$1),
          // right rail
          Positioned(
            right: 10,
            bottom: widget.bottom + 18,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => openCreator(context, c.id),
                  child: SizedBox(
                    width: 54,
                    height: 62,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Avatar(img: c.img, size: 50, border: Colors.white),
                        Positioned(
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              st.toggleFollow(c.id, c.name);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: following ? Colors.white : null,
                                gradient: following ? null : UC.brandGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(following ? Icons.check_rounded : Icons.add_rounded, size: 15, color: following ? UC.primary : Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _RailBtn(
                  liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  fmtK(r.likes + (liked ? 1 : 0)),
                  label: 'Like',
                  color: liked ? const Color(0xFFFF3B6B) : Colors.white,
                  pop: liked,
                  onTap: _like,
                ),
                _RailBtn(Icons.mode_comment_rounded, fmtK(r.comments + extraComments), label: 'Comments', onTap: () => _comments(context)),
                _RailBtn(Icons.card_giftcard_rounded, 'Gift', label: 'Send a gift', color: UC.gold, onTap: () => _gift(context)),
                _RailBtn(
                  saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  saved ? 'Saved' : 'Save',
                  label: 'Save',
                  color: saved ? UC.gold : Colors.white,
                  pop: saved,
                  onTap: () => st.toggleIn(st.savedReels, r.id),
                ),
                _RailBtn(Icons.reply_rounded, fmtK(r.shares), label: 'Share', flip: true, onTap: () => _share(context)),
                _RailBtn(Icons.more_horiz_rounded, '', label: 'More', onTap: () => _more(context)),
                const SizedBox(height: 4),
                RotationTransition(
                  turns: disc,
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [Color(0xFF222222), Color(0xFF555555), Color(0xFF222222)]),
                    ),
                    child: Avatar(img: c.img, size: 24),
                  ),
                ),
              ],
            ),
          ),
          // caption block
          Positioned(
            left: 14,
            right: 84,
            bottom: widget.bottom + 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.live)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Pressable(
                      onTap: () => openCreatorLive(context, c),
                      label: 'Watch ${c.name} live',
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                        decoration: BoxDecoration(gradient: UC.brandGradient, borderRadius: BorderRadius.circular(99)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const LiveBadge(scale: .8),
                            const SizedBox(width: 6),
                            Text(
                              'Live now · tap to join',
                              style: ts(12.5, w: FontWeight.w800, c: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => openCreator(context, c.id),
                      child: Text(
                        '@${c.handle}',
                        style: ts(16, w: FontWeight.w800, c: Colors.white),
                      ),
                    ),
                    if (c.verified) ...[const SizedBox(width: 4), const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF6FB1FF))],
                    const SizedBox(width: 10),
                    if (!following)
                      GestureDetector(
                        onTap: () => st.toggleFollow(c.id, c.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: .8), width: 1.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Follow',
                            style: ts(12.5, w: FontWeight.w800, c: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => expanded = !expanded),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    alignment: Alignment.topLeft,
                    child: Text(
                      r.caption,
                      maxLines: expanded ? 6 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: ts(14, w: FontWeight.w600, c: Colors.white, h: 1.35),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    DarkChip(r.cat, icon: categoryByName(r.cat).icon),
                    const SizedBox(width: 8),
                    const Icon(Icons.music_note_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(child: _Marquee(r.song, running: widget.active && !paused)),
                  ],
                ),
              ],
            ),
          ),
          // progress line
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.bottom,
            child: AnimatedBuilder(
              animation: prog,
              builder: (_, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: prog.value,
                  child: Container(height: 2.5, color: Colors.white.withValues(alpha: .85)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _comments(BuildContext context) {
    final ctl = TextEditingController();
    final mine = <String>[];
    showUmiSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${fmtK(r.comments + extraComments)} comments',
                textAlign: TextAlign.center,
                style: ts(15, w: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in mine.reversed) _comment(AppState.I.firstName, 'assets/img/me.jpg', m, 'now', 0),
                    for (final c in reelComments) _comment(c.$1, c.$2, c.$3, c.$4, c.$5),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 52,
                padding: const EdgeInsets.only(left: 6, right: 6),
                decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  children: [
                    const Avatar(img: 'assets/img/me.jpg', size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: ctl,
                        style: ts(14.5, w: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: ts(14.5, w: FontWeight.w600, c: UC.muted),
                        ),
                      ),
                    ),
                    Pressable(
                      label: 'Post comment',
                      onTap: () {
                        if (ctl.text.trim().isEmpty) return;
                        set(() => mine.add(ctl.text.trim()));
                        setState(() => extraComments++);
                        ctl.clear();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comment(String n, String img, String t, String when, int likes) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(img: img, name: n, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$n · $when',
                style: ts(12.5, w: FontWeight.w700, c: UC.muted),
              ),
              const SizedBox(height: 2),
              Text(t, style: ts(14.5, w: FontWeight.w600, h: 1.3)),
            ],
          ),
        ),
        Column(
          children: [
            const Icon(Icons.favorite_border_rounded, size: 18, color: UC.muted),
            if (likes > 0)
              Text(
                '$likes',
                style: ts(11, w: FontWeight.w700, c: UC.muted),
              ),
          ],
        ),
      ],
    ),
  );

  void _gift(BuildContext context) {
    final c = r.creator;
    showUmiSheet(
      context,
      (ctx) => ListenableBuilder(
        listenable: AppState.I,
        builder: (ctx, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Avatar(img: c.img, size: 40),
                const SizedBox(width: 10),
                Expanded(child: Text('Gift ${c.name.split(' ').first}', style: ds(22))),
                CoinPill(AppState.I.coins, onTap: () => Navigator.pushNamed(context, '/coins')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Gifts on reels go straight to the creator as diamonds.',
              style: ts(13, w: FontWeight.w500, c: UC.muted),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .82,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final g in gifts)
                  Pressable(
                    label: 'Send ${g.name}',
                    onTap: () {
                      if (!AppState.I.spend(g.price)) {
                        Navigator.pop(ctx);
                        toast(context, 'Not enough coins. Recharge to send ${g.name}.');
                        return;
                      }
                      Navigator.pop(ctx);
                      HapticFeedback.mediumImpact();
                      final id = _burstId++;
                      setState(() => bursts.add((Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height / 2), id)));
                      Future.delayed(const Duration(milliseconds: 900), () {
                        if (mounted) setState(() => bursts.removeWhere((b) => b.$2 == id));
                      });
                      toast(context, 'Sent ${g.name} to ${c.name.split(' ').first} 💝');
                    },
                    child: Container(
                      decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GiftIcon(g.id, size: 38),
                          const SizedBox(height: 6),
                          Text(g.name, style: ts(12.5, w: FontWeight.w800)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CoinDot(size: 11),
                              const SizedBox(width: 3),
                              Text(
                                fmtIn(g.price),
                                style: ts(11.5, w: FontWeight.w700, c: UC.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _share(BuildContext context) {
    showUmiSheet(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share to', style: ds(22)),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in creators.take(5))
                  _shareTarget(Avatar(img: c.img, size: 56), c.name.split(' ').first, () {
                    Navigator.pop(ctx);
                    toast(context, 'Sent to ${c.name.split(' ').first}');
                  }),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final a in [
                (Icons.link_rounded, 'Copy link'),
                (Icons.repeat_rounded, 'Repost'),
                (Icons.download_rounded, 'Save video'),
                (Icons.ios_share_rounded, 'More'),
              ])
                _shareTarget(
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(color: UC.surface, shape: BoxShape.circle),
                    child: Icon(a.$1, color: UC.ink),
                  ),
                  a.$2,
                  () {
                    if (a.$2 == 'Copy link') Clipboard.setData(ClipboardData(text: 'https://umigo.app/r/${r.id}'));
                    Navigator.pop(ctx);
                    toast(context, a.$2 == 'Copy link' ? 'Link copied' : '${a.$2} coming with the backend');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareTarget(Widget icon, String label, VoidCallback onTap) => Pressable(
    onTap: onTap,
    label: label,
    child: SizedBox(
      width: 74,
      child: Column(
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ts(12, w: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  void _more(BuildContext context) {
    showUmiSheet(
      context,
      (ctx) => GroupedList(
        children: [
          GroupedRow(
            icon: Icons.not_interested_rounded,
            title: 'Not interested',
            tint: UC.muted,
            onTap: () {
              Navigator.pop(ctx);
              toast(context, 'We’ll show fewer reels like this');
            },
          ),
          GroupedRow(
            icon: Icons.music_note_rounded,
            title: 'Use this sound',
            tint: UC.deep,
            onTap: () {
              Navigator.pop(ctx);
              toast(context, 'Sound saved');
            },
          ),
          GroupedRow(
            icon: Icons.flag_rounded,
            title: 'Report',
            tint: UC.red,
            onTap: () {
              Navigator.pop(ctx);
              toast(context, 'Thanks. Umi Guard will review this reel.');
            },
          ),
        ],
      ),
    );
  }
}

class _RailBtn extends StatelessWidget {
  final IconData icon;
  final String text, label;
  final Color color;
  final bool pop, flip;
  final VoidCallback onTap;
  const _RailBtn(this.icon, this.text, {required this.label, required this.onTap, this.color = Colors.white, this.pop = false, this.flip = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Pressable(
      onTap: onTap,
      label: label,
      scale: .85,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(pop),
            tween: Tween(begin: pop ? .6 : 1, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Transform.flip(
              flipX: flip,
              child: Icon(
                icon,
                size: 32,
                color: color,
                shadows: const [Shadow(color: Color(0x66000000), blurRadius: 10)],
              ),
            ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              text,
              style: ts(12, w: FontWeight.w800, c: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 6)]),
            ),
          ],
        ],
      ),
    ),
  );
}

class _HeartBurst extends StatelessWidget {
  final Offset at;
  const _HeartBurst({super.key, required this.at});
  @override
  Widget build(BuildContext context) {
    final tilt = (Random(at.dx.toInt()).nextDouble() - .5) * .6;
    return Positioned(
      left: at.dx - 60,
      top: at.dy - 60,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 850),
          builder: (_, v, _) {
            final s = v < .3 ? Curves.easeOutBack.transform(v / .3) * 1.15 : 1.15 - (v - .3) * .2;
            return Opacity(
              opacity: v < .7 ? 1 : (1 - (v - .7) / .3),
              child: Transform.translate(
                offset: Offset(0, -40 * v),
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform.scale(
                    scale: s,
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF3B6B), UC.accent]).createShader(r),
                      child: const Icon(Icons.favorite_rounded, size: 120, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Song name that scrolls sideways while the reel plays.
class _Marquee extends StatefulWidget {
  final String text;
  final bool running;
  const _Marquee(this.text, {required this.running});
  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.running && !reduceMotion(context) ? a.repeat() : a.stop();
  }

  @override
  void didUpdateWidget(covariant _Marquee old) {
    super.didUpdateWidget(old);
    widget.running && !reduceMotion(context) ? a.repeat() : a.stop();
  }

  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = ts(13, w: FontWeight.w700, c: Colors.white);
    return ClipRect(
      child: LayoutBuilder(
        builder: (_, c) => AnimatedBuilder(
          animation: a,
          builder: (_, _) {
            final tp = TextPainter(
              text: TextSpan(text: '${widget.text}     ', style: style),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            final w = tp.width;
            return SizedBox(
              height: 20,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(-w * a.value, 0),
                  child: Text('${widget.text}     ${widget.text}     ', style: style, maxLines: 1, softWrap: false),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A reel thumbnail for grids (profile, category).
class ReelThumb extends StatelessWidget {
  final Reel reel;
  final VoidCallback onTap;
  final bool locked;
  const ReelThumb(this.reel, {super.key, required this.onTap, this.locked = false});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .96,
    label: reel.caption,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          fadeInAsset(reel.img),
          if (locked)
            ColoredBox(
              color: UC.inkA(.45),
              child: const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 26)),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x99000000)]),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Row(
              children: [
                const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                Text(
                  fmtK(reel.likes),
                  style: ts(11.5, w: FontWeight.w800, c: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Opens a creator's live in the demo viewer, with their access rules.
void openCreatorLive(BuildContext context, Creator c) {
  final h =
      demoHosts.where((h) => h.id == c.id).firstOrNull ??
      Host(c.id, c.name, c.img, '${c.cat} live with ${c.name.split(' ').first}', c.region, fmtK(c.followers ~/ 20), c.cat);
  Navigator.push(context, umiRoute((_) => LiveViewerScreen.demo(h)));
}
