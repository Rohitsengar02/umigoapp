import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// App-wide screen transition, tuned for speed: the new screen slides in a short
/// distance with a quick fade and a hint of scale, while the old one drifts left.
/// Built from transition widgets (no rebuilds, no saveLayer tints) so it stays at 60/120 fps.
const kPageIn = Duration(milliseconds: 300);
const kPageOut = Duration(milliseconds: 240);

class UmiPageTransitions extends PageTransitionsBuilder {
  const UmiPageTransitions();
  @override
  Duration get transitionDuration => kPageIn;
  @override
  Duration get reverseTransitionDuration => kPageOut;
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      UmiTransition(animation: animation, secondary: secondaryAnimation, child: child);
}

class UmiTransition extends StatelessWidget {
  final Animation<double> animation, secondary;
  final Widget child;
  const UmiTransition({super.key, required this.animation, required this.secondary, required this.child});

  static final _inSlide = Tween(begin: const Offset(.08, 0), end: Offset.zero);
  static final _outSlide = Tween(begin: Offset.zero, end: const Offset(-.06, 0));
  static final _inScale = Tween(begin: .985, end: 1.0);

  @override
  Widget build(BuildContext context) {
    final inC = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final fade = CurvedAnimation(parent: animation, curve: const Interval(0, .6, curve: Curves.easeOut), reverseCurve: Curves.easeIn);
    final outC = CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: _outSlide.animate(outC),
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: _inSlide.animate(inC),
          child: ScaleTransition(scale: _inScale.animate(inC), child: child),
        ),
      ),
    );
  }
}

/// Route with the Umigo transition, for screens pushed with a builder.
Route<T> umiRoute<T>(WidgetBuilder b) => PageRouteBuilder<T>(
  transitionDuration: kPageIn,
  reverseTransitionDuration: kPageOut,
  pageBuilder: (c, _, _) => b(c),
  transitionsBuilder: (c, a, s, child) => UmiTransition(animation: a, secondary: s, child: child),
);

/// Letter-by-letter reveal: each glyph rises out of a mask with a fade, one after another.
/// Changing [text] replays the animation.
class TextReveal extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration delay;
  final int perCharMs;
  final TextAlign align;
  const TextReveal(this.text, {super.key, required this.style, this.delay = Duration.zero, this.perCharMs = 28, this.align = TextAlign.start});
  @override
  State<TextReveal> createState() => _TextRevealState();
}

class _TextRevealState extends State<TextReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void didUpdateWidget(TextReveal old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _play();
  }

  void _play() {
    _t?.cancel();
    _c.duration = Duration(milliseconds: 520 + widget.text.length * widget.perCharMs);
    _c.value = 0;
    _t = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.text.characters.toList();
    final n = math.max(chars.length, 1);
    final totalMs = 520 + n * widget.perCharMs;
    final lines = <List<Widget>>[[]];
    var words = <Widget>[];
    var word = <Widget>[];
    void flushWord() {
      if (word.isNotEmpty) words.add(Row(mainAxisSize: MainAxisSize.min, children: word));
      word = [];
    }

    for (var i = 0; i < chars.length; i++) {
      final ch = chars[i];
      if (ch == '\n') {
        flushWord();
        lines.last.addAll(words);
        words = [];
        lines.add([]);
        continue;
      }
      if (ch == ' ') {
        flushWord();
        words.add(Text(' ', style: widget.style));
        continue;
      }
      final start = (i * widget.perCharMs) / totalMs;
      final end = math.min(1.0, start + 520 / totalMs);
      final a = CurvedAnimation(
        parent: _c,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
      word.add(
        AnimatedBuilder(
          animation: a,
          builder: (_, _) => ClipRect(
            child: Opacity(
              opacity: a.value,
              child: Transform.translate(
                offset: Offset(0, (1 - a.value) * (widget.style.fontSize ?? 20) * .9),
                child: Transform.rotate(
                  angle: (1 - a.value) * .12,
                  alignment: Alignment.bottomLeft,
                  child: Text(ch, style: widget.style),
                ),
              ),
            ),
          ),
        ),
      );
    }
    flushWord();
    lines.last.addAll(words);
    final wrapAlign = switch (widget.align) {
      TextAlign.center => WrapAlignment.center,
      TextAlign.right || TextAlign.end => WrapAlignment.end,
      _ => WrapAlignment.start,
    };
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: switch (widget.align) {
            TextAlign.center => CrossAxisAlignment.center,
            TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
            _ => CrossAxisAlignment.start,
          },
          children: [for (final l in lines) Wrap(alignment: wrapAlign, children: l)],
        ),
      ),
    );
  }
}

/// Fades and slides a child up after `index * step` ms: use on lists of fields or cards
/// so they arrive one after another.
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  final int stepMs;
  final int baseMs;
  final double dy;
  const StaggerIn({super.key, required this.index, required this.child, this.stepMs = 70, this.baseMs = 120, this.dy = 26});
  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
  late final Animation<double> _f = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, .6, curve: Curves.easeOut),
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.baseMs + widget.index * widget.stepMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _f.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _a.value) * widget.dy),
        child: Transform.scale(scale: .96 + .04 * _a.value.clamp(0, 1.02), child: child),
      ),
    ),
  );
}

/// Wraps each widget so a list arrives one item after another.
List<Widget> staggerAll(List<Widget> items, {int stepMs = 60, int baseMs = 80}) => [
  for (var i = 0; i < items.length; i++) StaggerIn(index: i, stepMs: stepMs, baseMs: baseMs, child: items[i]),
];

/// Same for CustomScrollView slivers: box adapters get a staggered entrance, other slivers pass through.
List<Widget> staggerSlivers(List<Widget> slivers, {int stepMs = 70, int baseMs = 60}) {
  var i = 0;
  return [
    for (final s in slivers)
      if (s is SliverToBoxAdapter && s.child != null)
        SliverToBoxAdapter(
          key: s.key,
          child: StaggerIn(index: i++, stepMs: stepMs, baseMs: baseMs, child: s.child!),
        )
      else
        s,
  ];
}
