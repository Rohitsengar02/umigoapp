import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:livekit_client/livekit_client.dart';

import '../data/demo_data.dart';
import '../live/live_session.dart';
import '../theme.dart';
import 'skeleton.dart';
import 'common.dart';
import 'gift_icons.dart';
import 'ui.dart';

import 'dart:ui' as ui;

/// The video layer: a LiveKit track when we have one, otherwise a photo.
class LiveVideo extends StatelessWidget {
  final VideoTrack? track;
  final String? fallbackImg;
  final bool mirror;
  final String? heroTag;
  const LiveVideo({super.key, this.track, this.fallbackImg, this.mirror = false, this.heroTag});
  @override
  Widget build(BuildContext context) {
    final t = track;
    if (t != null) {
      return ColoredBox(
        color: UC.ink,
        child: VideoTrackRenderer(t, fit: VideoViewFit.cover, mirrorMode: mirror ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off),
      );
    }
    if (fallbackImg != null) {
      final img = fadeInAsset(fallbackImg!, w: double.infinity, h: double.infinity);
      return heroTag == null ? img : Hero(tag: heroTag!, child: img);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [UC.deep, UC.ink]),
      ),
    );
  }
}

class ShadeOverlay extends StatelessWidget {
  const ShadeOverlay({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [UC.inkA(.55), UC.inkA(0), UC.inkA(0), UC.inkA(.82)],
          stops: const [0, .22, .46, 1],
        ),
      ),
      child: const SizedBox.expand(),
    ),
  );
}

/// Scrolling live chat (newest at the bottom).
class ChatFeed extends StatelessWidget {
  final List<LiveEvent> events;
  final void Function(LiveEvent e)? onTap;
  const ChatFeed({super.key, required this.events, this.onTap});
  @override
  Widget build(BuildContext context) {
    final list = events.where((e) => e.type != LiveEventType.like).toList();
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black, Colors.black],
        stops: [0, .18, 1],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.only(top: 30),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[list.length - 1 - i];
          final tappable = onTap != null && e.type == LiveEventType.chat && !e.mine;
          return tappable ? GestureDetector(onTap: () => onTap!(e), child: _line(e)) : _line(e);
        },
      ),
    );
  }

  Widget _line(LiveEvent e) {
    if (e.type == LiveEventType.mod) {
      return _bubble(UC.inkA(.0), const Color(0x8C6B4A6E), [
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(right: 5),
            child: Icon(Icons.shield_rounded, size: 13, color: UC.gold),
          ),
        ),
        TextSpan(
          text: '${e.name} ',
          style: ts(12, w: FontWeight.w800, c: UC.gold, h: 1.4),
        ),
        TextSpan(
          text: e.text,
          style: ts(12, w: FontWeight.w700, c: Colors.white, h: 1.4),
        ),
      ]);
    }
    if (e.type == LiveEventType.system) {
      return _bubble(UC.inkA(.0), Colors.white.withValues(alpha: .14), [
        TextSpan(
          text: e.text,
          style: ts(12, w: FontWeight.w600, c: Colors.white, h: 1.4),
        ),
      ]);
    }
    final gift = e.type == LiveEventType.gift;
    final lvBg = e.lv > 30
        ? UC.accentText
        : e.lv > 10
        ? UC.primary
        : UC.deep;
    final nameColor = e.mine
        ? const Color(0xFFFFD27A)
        : gift
        ? const Color(0xFFFFE2B8)
        : const Color(0xFFFFC4E3);
    final text = switch (e.type) {
      LiveEventType.gift => 'sent ${giftById(e.giftId).name}${e.qty > 1 ? ' ×${e.qty}' : ''}',
      _ => e.text,
    };
    return _bubble(Colors.transparent, gift ? const Color(0x6BFF9F80) : UC.inkA(.42), [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: lvBg, borderRadius: BorderRadius.circular(99)),
          child: Text(
            'Lv ${e.lv}',
            style: ts(9.5, w: FontWeight.w800, c: Colors.white),
          ),
        ),
      ),
      TextSpan(
        text: '${e.name} ',
        style: ts(12.5, w: FontWeight.w800, c: nameColor),
      ),
      TextSpan(
        text: text,
        style: ts(12.5, w: FontWeight.w600, c: e.masked ? Colors.white.withValues(alpha: .8) : Colors.white, h: 1.35),
      ),
      if (gift)
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(padding: const EdgeInsets.only(left: 4), child: GiftIcon(e.giftId, size: 16)),
        ),
    ]);
  }

  Widget _bubble(Color _, Color bg, List<InlineSpan> spans) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text.rich(TextSpan(children: spans)),
    ),
  );
}

/// Slide-in "X sent Rocket ×3" banner plus a big centre animation for pricey gifts.
class GiftOverlay extends StatefulWidget {
  final Stream<LiveEvent> gifts;
  const GiftOverlay({super.key, required this.gifts});
  @override
  State<GiftOverlay> createState() => _GiftOverlayState();
}

class _GiftOverlayState extends State<GiftOverlay> with TickerProviderStateMixin {
  StreamSubscription? _sub;
  final _queue = <LiveEvent>[];
  LiveEvent? _cur;
  late final AnimationController _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _big = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  LiveEvent? _bigEv;

  @override
  void initState() {
    super.initState();
    _sub = widget.gifts.listen((e) {
      _queue.add(e);
      _next();
      if (giftById(e.giftId).price >= 299) {
        setState(() => _bigEv = e);
        _big.forward(from: 0);
      }
    });
    _slide.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _cur = null;
        _next();
      }
    });
  }

  void _next() {
    if (_cur != null || _queue.isEmpty) return;
    setState(() => _cur = _queue.removeAt(0));
    _slide.forward(from: 0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _slide.dispose();
    _big.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          if (_cur != null)
            Positioned(
              left: 10,
              top: 0,
              child: AnimatedBuilder(
                animation: _slide,
                builder: (_, child) {
                  final v = _slide.value;
                  final x = v < .12
                      ? (1 - v / .12)
                      : v > .85
                      ? (v - .85) / .15
                      : 0.0;
                  return Transform.translate(offset: Offset(-320 * x, 0), child: child);
                },
                child: _banner(_cur!),
              ),
            ),
          if (_bigEv != null)
            Center(
              child: AnimatedBuilder(
                animation: _big,
                builder: (_, _) {
                  final v = _big.value;
                  final scale = Curves.elasticOut.transform((v * 1.6).clamp(0, 1)) * (1 + .1 * sin(v * 12));
                  final op = v < .8 ? 1.0 : (1 - (v - .8) / .2);
                  return Opacity(
                    opacity: op.clamp(0, 1),
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GiftIcon(_bigEv!.giftId, size: 150),
                          Text(
                            '${_bigEv!.name} · ${giftById(_bigEv!.giftId).name}${_bigEv!.qty > 1 ? ' ×${_bigEv!.qty}' : ''}',
                            style: ts(18, w: FontWeight.w800, c: Colors.white).copyWith(shadows: [Shadow(color: UC.inkA(.6), blurRadius: 8)]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _banner(LiveEvent e) => Container(
    height: 52,
    padding: const EdgeInsets.only(left: 6, right: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [UC.primary, UC.accent.withValues(alpha: .85), UC.accent.withValues(alpha: 0)], stops: const [0, .6, 1]),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(name: e.name, size: 40, border: Colors.white),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.name,
              style: ts(13, w: FontWeight.w800, c: Colors.white),
            ),
            Text(
              'sent a ${giftById(e.giftId).name}',
              style: ts(11.5, w: FontWeight.w700, c: Colors.white.withValues(alpha: .9)),
            ),
          ],
        ),
        const SizedBox(width: 8),
        GiftIcon(e.giftId, size: 38),
        if (e.qty > 1) ...[
          const SizedBox(width: 4),
          Text(
            '×${e.qty}',
            style: ts(26, w: FontWeight.w800, c: UC.gold).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    ),
  );
}

/// Hearts that float up from the like button.
class FloatingHearts extends StatefulWidget {
  final Stream<void> taps;
  const FloatingHearts({super.key, required this.taps});
  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts> with TickerProviderStateMixin {
  final _hearts = <(AnimationController, double, Color)>[];
  StreamSubscription? _sub;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _sub = widget.taps.listen((_) => _add());
  }

  void _add() {
    if (_hearts.length > 18) return;
    final c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + _rnd.nextInt(900)),
    );
    final item = (c, (_rnd.nextDouble() - .5) * 50, [UC.primary, UC.accent, Colors.white, UC.gold][_rnd.nextInt(4)]);
    setState(() => _hearts.add(item));
    c.forward().then((_) {
      if (!mounted) return;
      setState(() => _hearts.remove(item));
      c.dispose();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final h in _hearts) {
      h.$1.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: 80,
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final h in _hearts)
            AnimatedBuilder(
              animation: h.$1,
              builder: (_, _) {
                final v = h.$1.value;
                return Positioned(
                  left: 28 + h.$2 * v + 8 * sin(v * 9),
                  bottom: v * 240,
                  child: Opacity(
                    opacity: v < .15 ? v / .15 : (1 - v).clamp(0, 1),
                    child: Transform.scale(
                      scale: .6 + v * .5,
                      child: Icon(Icons.favorite_rounded, color: h.$3, size: 26),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}

class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double height;

  /// true when the pill sits in an Expanded and its child should fill it.
  final bool expand;
  const GlassPill({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 10), this.height = 26, this.expand = false});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .24),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
        ),
        child: expand ? child : Row(mainAxisSize: MainAxisSize.min, children: [child]),
      ),
    ),
  );
}

class RoundGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;
  final Gradient? gradient;
  final double size;
  const RoundGlassButton(this.icon, {super.key, required this.onTap, required this.tooltip, this.color, this.gradient, this.size = 44});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Pressable(
      onTap: onTap,
      scale: .9,
      label: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: gradient != null
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                  boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .4), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: color ?? Colors.white, size: size * .48),
              )
            : ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: .22),
                      border: Border.all(color: Colors.white.withValues(alpha: .22)),
                    ),
                    child: Icon(icon, color: color ?? Colors.white, size: size * .48),
                  ),
                ),
              ),
      ),
    ),
  );
}
