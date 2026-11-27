import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Shimmer sweep over skeleton shapes. One controller per Shimmer, so wrap a whole
/// block of placeholders in a single Shimmer rather than each box.
class Shimmer extends StatefulWidget {
  final Widget child;
  final bool dark;
  const Shimmer({super.key, required this.child, this.dark = false});
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.dark ? const Color(0x33FFFFFF) : UC.surface;
    final hi = widget.dark ? const Color(0x66FFFFFF) : Colors.white;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, hi, base],
          stops: const [.35, .5, .65],
          transform: _Slide(_c.value),
        ).createShader(r),
        child: child,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  final double t;
  const _Slide(this.t);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

/// A grey rounded block (use inside a [Shimmer]).
class Bone extends StatelessWidget {
  final double? w, h;
  final double r;
  final bool circle;
  const Bone({super.key, this.w, this.h, this.r = 12, this.circle = false});
  @override
  Widget build(BuildContext context) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFFF3E8EE),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(r),
    ),
  );
}

/// Placeholder for the 2-column live grid.
Widget liveGridSkeletonSliver({int count = 4}) => SliverToBoxAdapter(
  child: Shimmer(
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 250),
      itemCount: count,
      itemBuilder: (_, _) => const Bone(r: 28),
    ),
  ),
);

/// Placeholder rows: avatar + two lines.
class ListSkeleton extends StatelessWidget {
  final int rows;
  const ListSkeleton({super.key, this.rows = 6});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                const Bone(w: 44, h: 44, circle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone(w: 120 + (i % 3) * 30, h: 13, r: 6),
                      const SizedBox(height: 8),
                      Bone(w: 180 - (i % 2) * 40, h: 11, r: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Story circles placeholder.
class StoriesSkeleton extends StatelessWidget {
  const StoriesSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Row(
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(children: [Bone(w: 66, h: 66, circle: true), SizedBox(height: 7), Bone(w: 44, h: 10, r: 5)]),
          ),
      ],
    ),
  );
}

/// Full-screen dark placeholder while a live connects.
class LiveConnectingSkeleton extends StatelessWidget {
  const LiveConnectingSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    Widget dark(double w, double h, {double r = 12, bool circle = false}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(r),
      ),
    );
    return Shimmer(
      dark: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, pad.top + 12, 14, pad.bottom + 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [dark(40, 40, circle: true), const SizedBox(width: 8), dark(110, 14, r: 7), const Spacer(), dark(34, 34, circle: true)]),
            const Spacer(),
            for (final w in [220.0, 170.0, 240.0]) Padding(padding: const EdgeInsets.only(bottom: 8), child: dark(w, 30, r: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: dark(double.infinity, 44, r: 22)),
                const SizedBox(width: 8),
                dark(44, 44, circle: true),
                const SizedBox(width: 6),
                dark(44, 44, circle: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Image.asset with a shimmer while the first frame decodes, then a quick fade in.
Widget fadeInAsset(String path, {double? w, double? h, BoxFit fit = BoxFit.cover}) => Image.asset(
  path,
  width: w,
  height: h,
  fit: fit,
  frameBuilder: (context, child, frame, sync) {
    if (sync) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (frame == null)
          Positioned.fill(
            child: Shimmer(child: Container(color: UC.surface)),
          ),
        AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 220), child: child),
      ],
    );
  },
);
