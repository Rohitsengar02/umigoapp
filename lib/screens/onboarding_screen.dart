import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gift_icons.dart';
import '../widgets/mascot.dart';
import '../widgets/ui.dart';

/// Three intro pages before sign up. Each picture drifts with the swipe (parallax),
/// the dots stretch, and the last page turns the button into "Create account".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const _pages = [
  ('Welcome to Umigo', 'Go ', 'live', ' in one tap', 'Share your world with real people, right now. No studio needed, just your phone.'),
  ('Support creators', 'Gifts that ', 'glow', '', 'Send hearts, roses and rockets. Hosts turn every gift into diamonds they can cash out.'),
  ('Umi Guard', 'Safe by ', 'design', '', 'Umi filters rude chat and checks video on your phone, so every live stays friendly.'),
];

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final pc = PageController();
  double page = 0;
  late final AnimationController float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void initState() {
    super.initState();
    pc.addListener(() => setState(() => page = pc.page ?? 0));
  }

  @override
  void dispose() {
    pc.dispose();
    float.dispose();
    super.dispose();
  }

  int get i => page.round();
  bool get last => i == _pages.length - 1;

  void _next() {
    if (last) {
      Navigator.pushNamed(context, '/register');
    } else {
      pc.nextPage(duration: const Duration(milliseconds: 560), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: AuroraBg(
        colors: [
          Color.lerp(UC.blush, UC.peach, (page).clamp(0, 1))!,
          Color.lerp(UC.lilac, UC.mint, (page - 1).clamp(0, 1))!,
          Color.lerp(UC.peach, UC.lilac, (page / 2).clamp(0, 1))!,
        ],
        child: Column(
          children: [
            SizedBox(height: pad.top + 8),
            // top: wordmark + skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Text('umigo', style: ds(24, c: UC.ink, ls: -1)),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: last ? 0 : 1,
                      child: Pressable(
                        onTap: last ? null : () => pc.animateToPage(_pages.length - 1, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic),
                        label: 'Skip intro',
                        child: Glass(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          child: Text('Skip', style: ts(14, w: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pc,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                itemBuilder: (_, k) {
                  final d = page - k; // -1..1 while swiping
                  final (eyebrow, lead, accent, tail, body) = _pages[k];
                  return Column(
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(d * -120, 0),
                          child: Opacity(
                            opacity: (1 - d.abs() * .8).clamp(0, 1),
                            child: Center(
                              child: SizedBox(
                                height: math.min(h * .42, 380),
                                child: AspectRatio(aspectRatio: 1, child: _art(k)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(d * -40, 0),
                        child: Opacity(
                          opacity: (1 - d.abs() * 1.6).clamp(0, 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Eyebrow(eyebrow),
                                const SizedBox(height: 10),
                                HeroTitle(lead, accent, tail: tail, size: 42),
                                const SizedBox(height: 12),
                                Text(
                                  body,
                                  style: ts(16, w: FontWeight.w500, c: UC.muted, h: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            // dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                children: [
                  for (var k = 0; k < _pages.length; k++)
                    Builder(
                      builder: (_) {
                        final t = (1 - (page - k).abs()).clamp(0.0, 1.0);
                        return Container(
                          width: 8 + 22 * t,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: Color.lerp(UC.ink.withValues(alpha: .15), UC.ink, t), borderRadius: BorderRadius.circular(9)),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, pad.bottom + 16),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(a), child: c),
                    ),
                    child: last
                        ? PrimaryButton('Create account', key: const ValueKey('create'), icon: Icons.arrow_forward_rounded, onTap: _next)
                        : PrimaryButton('Next', key: const ValueKey('next'), dark: true, icon: Icons.arrow_forward_rounded, onTap: _next),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 46,
                    child: Pressable(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      label: 'I already have an account',
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Have an account? ',
                            style: ts(15, w: FontWeight.w600, c: UC.muted),
                            children: [
                              TextSpan(
                                text: 'Log in',
                                style: ts(15, w: FontWeight.w800, c: UC.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating offset for decorative bits: each one bobs on its own phase.
  Offset _bob(double phase, [double amp = 8]) {
    final t = float.value * 2 * math.pi + phase;
    return Offset(math.cos(t) * amp * .4, math.sin(t) * amp);
  }

  Widget _art(int k) => AnimatedBuilder(
    animation: float,
    builder: (_, _) => LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth;
        return switch (k) {
          0 => _artLive(s),
          1 => _artGifts(s),
          _ => _artSafe(s),
        };
      },
    ),
  );

  Widget _photo(String img, double w, double h, double angle, {bool live = false, String? name}) => Transform.rotate(
    angle: angle,
    child: Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(w * .16),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: UC.inkA(.18), blurRadius: 30, offset: const Offset(0, 16))],
        image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (live) const LiveBadge(),
            const Spacer(),
            if (name != null) Text(name, style: ds(w * .12, c: Colors.white)),
          ],
        ),
      ),
    ),
  );

  Widget _artLive(double s) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(left: s * .02, top: s * .16 + _bob(0).dy, child: _photo('assets/img/zara.jpg', s * .42, s * .56, -.14)),
      Positioned(right: s * .02, top: s * .1 + _bob(2).dy, child: _photo('assets/img/kabir.jpg', s * .42, s * .56, .13)),
      Positioned(
        left: s * .24,
        top: s * .04 + _bob(4, 5).dy,
        child: _photo('assets/img/priya.jpg', s * .52, s * .7, 0, live: true, name: 'Priya'),
      ),
      Positioned(
        right: s * .04,
        bottom: s * .06 + _bob(1, 10).dy,
        child: Glass(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_rounded, size: 17, color: UC.primary),
              const SizedBox(width: 6),
              Text('2.4K watching', style: ts(14, w: FontWeight.w800)),
            ],
          ),
        ),
      ),
      Positioned(left: s * .06, bottom: s * .12 + _bob(3, 12).dy, child: const GiftIcon('heart', size: 44)),
      Positioned(left: s * .16, bottom: s * .0 + _bob(5, 9).dy, child: const GiftIcon('heart', size: 28)),
    ],
  );

  Widget _artGifts(double s) {
    const ids = ['rose', 'rocket', 'crown', 'star', 'ring', 'coffee'];
    final r = s * .38;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Container(
            width: s * .58,
            height: s * .58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: UC.card,
              boxShadow: [BoxShadow(color: UC.accent.withValues(alpha: .35), blurRadius: 50, offset: const Offset(0, 20))],
            ),
            alignment: Alignment.center,
            child: GiftIcon('car', size: s * .34),
          ),
        ),
        for (var k = 0; k < ids.length; k++)
          Builder(
            builder: (_) {
              final a = k / ids.length * 2 * math.pi + float.value * 2 * math.pi * .25;
              return Positioned(
                left: s / 2 + math.cos(a) * r - 28,
                top: s / 2 + math.sin(a) * r - 28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: UC.card,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: UC.inkA(.10), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: GiftIcon(ids[k], size: 32),
                ),
              );
            },
          ),
        Positioned(
          left: s * .0,
          top: s * .02 + _bob(0, 6).dy,
          child: Glass(
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinDot(size: 24),
                const SizedBox(width: 6),
                Text(
                  '+499',
                  style: ts(15, w: FontWeight.w800, c: UC.accentText),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: s * .0,
          bottom: s * .04 + _bob(2, 6).dy,
          child: Glass(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DiamondIcon(size: 20),
                const SizedBox(width: 6),
                Text('Diamonds earned', style: ts(14, w: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _artSafe(double s) {
    Widget chip(String t, IconData ic, Color c) => Glass(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: c.withValues(alpha: .15), shape: BoxShape.circle),
            child: Icon(ic, size: 15, color: c),
          ),
          const SizedBox(width: 7),
          Text(t, style: ts(14, w: FontWeight.w800)),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Container(
            width: s * .7,
            height: s * .7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Colors.white, Colors.white.withValues(alpha: .4)]),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: UC.green.withValues(alpha: .2), blurRadius: 50, offset: const Offset(0, 20))],
            ),
            alignment: Alignment.center,
            child: Mascot(mood: 'love', size: s * .46),
          ),
        ),
        Positioned(left: 0, top: s * .1 + _bob(0, 6).dy, child: chip('Chat filter', Icons.chat_bubble_rounded, UC.green)),
        Positioned(right: 0, top: s * .4 + _bob(2, 6).dy, child: chip('Video guard', Icons.shield_rounded, UC.primary)),
        Positioned(left: s * .06, bottom: s * .04 + _bob(4, 6).dy, child: chip('Instant mute', Icons.volume_off_rounded, UC.deep)),
      ],
    );
  }
}
