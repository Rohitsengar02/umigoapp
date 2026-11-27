import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Shared building blocks for the soft glass look: pastel backdrop, glass for the floating
/// layer only (tab bar, top buttons), white cards for content, spring press feedback.

/// Space a tab page leaves at the bottom so content can scroll out from under the floating tab bar.
double navSpace(BuildContext context) => MediaQuery.paddingOf(context).bottom + 104;

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Near-white page with soft pastel light in the corners (cheap radial gradients, no blur).
class AuroraBg extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  const AuroraBg({super.key, required this.child, this.colors});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: UC.bg),
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: _AuroraPainter(colors ?? [UC.blush, UC.lilac, UC.peach]))),
          ),
        ),
        child,
      ],
    ),
  );
}

class _AuroraPainter extends CustomPainter {
  final List<Color> c;
  _AuroraPainter(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    void glow(Offset o, double r, Color col, double a) {
      final rect = Rect.fromCircle(center: o, radius: r);
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              col.withValues(alpha: a),
              col.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    glow(Offset(s.width * .95, s.height * .02), s.width * .85, c[1], .95);
    glow(Offset(s.width * .05, s.height * .06), s.width * .7, c[0], .8);
    glow(Offset(s.width * .1, s.height * .55), s.width * .6, c[2], .55);
    glow(Offset(s.width * 1.0, s.height * .8), s.width * .6, c[0], .45);
  }

  @override
  bool shouldRepaint(_AuroraPainter o) => !listEquals(o.c, c);
}

/// Frosted glass. Use it for things that float above content (bars, overlay buttons), not for cards.
class Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? tint;
  final bool shadow;
  const Glass({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(99)),
    this.padding,
    this.blur = 22,
    this.tint,
    this.shadow = true,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: radius,
      boxShadow: shadow ? [BoxShadow(color: UC.inkA(.10), blurRadius: 30, offset: const Offset(0, 12))] : null,
    ),
    child: ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? UC.glass,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: UC.dark ? .08 : .7), width: 1),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: .16), Colors.white.withValues(alpha: 0)],
              stops: const [0, .5],
            ),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// Scales down a touch on press with a spring back, plus a light haptic. Wrap any tappable.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final String? label;
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = .96, this.haptic = true, this.label});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _s = Tween(
    begin: 1.0,
    end: widget.scale,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut, reverseCurve: Curves.elasticOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.onTap != null) _c.forward();
  }

  void _up([_]) => _c.reverse();

  @override
  Widget build(BuildContext context) {
    final w = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _up,
      onLongPress: widget.onLongPress,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: ScaleTransition(scale: _s, child: widget.child),
    );
    return widget.label == null ? w : Semantics(button: true, label: widget.label, child: w);
  }
}

/// Small spaced capitals above a title: "LIVE NOW · 3 STREAMING".
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: ts(12, w: FontWeight.w800, c: color ?? UC.muted, ls: 1.6),
  );
}

/// Big headline where one word carries the brand gradient: HeroTitle('Find your ', 'vibe').
class HeroTitle extends StatelessWidget {
  final String lead, accent, tail;
  final double size;
  final Color? color;
  final TextAlign align;
  const HeroTitle(this.lead, this.accent, {super.key, this.tail = '', this.size = 34, this.color, this.align = TextAlign.start});
  @override
  Widget build(BuildContext context) {
    final style = ds(size, c: color, h: 1.06);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: lead),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GradientText(accent, style: style),
          ),
          if (tail.isNotEmpty) TextSpan(text: tail),
        ],
      ),
      textAlign: align,
      style: style,
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  const GradientText(this.text, {super.key, required this.style, this.gradient = UC.brandGradient});
  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) => gradient.createShader(Rect.fromLTWH(0, 0, r.width, r.height)),
    child: Text(text, style: style.copyWith(color: Colors.white)),
  );
}

/// White content card with a soft, wide shadow.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 28, this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? UC.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: UC.dark ? UC.line : Colors.white, width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .07), blurRadius: 30, offset: const Offset(0, 14)),
          BoxShadow(color: UC.inkA(.03), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap, scale: .98, child: card);
  }
}

/// Round glass button for the top of a screen (menu, back, bell...).
class GlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final double size;
  final bool dot;
  final Color? fg;
  const GlassCircle(this.icon, {super.key, this.onTap, required this.label, this.size = 44, this.dot = false, this.fg});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Glass(
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * .48, color: fg ?? UC.ink),
            ),
          ),
          if (dot)
            Positioned(
              top: size * .22,
              right: size * .24,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: UC.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: UC.card, width: 1.6),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Section title with an optional subtitle and action: "Live now   See all".
class SectionHead extends StatelessWidget {
  final String title;
  final String? sub, action;
  final VoidCallback? onAction;
  final Widget? trailing;
  const SectionHead(this.title, {super.key, this.sub, this.action, this.onAction, this.trailing});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ds(23, c: UC.ink)),
            if (sub != null) ...[
              const SizedBox(height: 3),
              Text(
                sub!,
                style: ts(13.5, w: FontWeight.w600, c: UC.muted),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
      if (action != null)
        Pressable(
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(
              action!,
              style: ts(13.5, w: FontWeight.w800, c: UC.primary),
            ),
          ),
        ),
    ],
  );
}

/// Big pill search field with a filter button on the right.
class SearchPill extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focus;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;
  final bool filterOn;
  const SearchPill({super.key, required this.controller, this.focus, this.hint = 'Search', this.onChanged, this.onFilter, this.filterOn = false});
  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.only(left: 20, right: 8),
    decoration: BoxDecoration(
      color: UC.card.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: UC.dark ? UC.line : Colors.white, width: 1.2),
      boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .10), blurRadius: 30, offset: const Offset(0, 12))],
    ),
    child: Row(
      children: [
        Icon(Icons.search_rounded, color: UC.muted, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: ts(16, w: FontWeight.w600, c: UC.ink),
            cursorColor: UC.primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: ts(16, w: FontWeight.w500, c: UC.muted.withValues(alpha: .85)),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (_, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    key: const ValueKey('x'),
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                    icon: Icon(Icons.cancel_rounded, color: UC.muted, size: 20),
                  ),
          ),
        ),
        if (onFilter != null)
          Pressable(
            onTap: onFilter,
            label: 'Sort and filter',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: filterOn ? UC.pill : UC.surface, shape: BoxShape.circle),
              child: Icon(Icons.tune_rounded, size: 21, color: filterOn ? Colors.white : UC.ink),
            ),
          ),
      ],
    ),
  );
}

/// Round category button with a label underneath. Selected = brand gradient.
class CategoryBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;
  const CategoryBubble({super.key, required this.label, required this.icon, required this.tint, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    child: SizedBox(
      width: 76,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? null : UC.card,
              gradient: selected ? UC.brandGradient : null,
              border: Border.all(color: UC.dark ? UC.line : Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: selected ? UC.primary.withValues(alpha: .35) : const Color(0xFF6B4A6E).withValues(alpha: .08),
                  blurRadius: selected ? 20 : 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: selected ? Colors.white : tint, size: 27),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: ts(13, w: selected ? FontWeight.w800 : FontWeight.w600, c: selected ? UC.ink : UC.muted),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    ),
  );
}

/// Small rounded label on top of photos: glass-dark with white text.
class PhotoChip extends StatelessWidget {
  final Widget? leading;
  final String text;
  const PhotoChip(this.text, {super.key, this.leading});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        color: Colors.white.withValues(alpha: .18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 5)],
            Text(
              text,
              style: ts(13, w: FontWeight.w700, c: Colors.white),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Inner screen header: glass back button, then a large title (and optional actions).
class LargeTitle extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final List<Widget> actions;
  final bool back;
  const LargeTitle(this.title, {super.key, this.eyebrow, this.actions = const [], this.back = true});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (back) GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
            const Spacer(),
            ...actions,
          ],
        ),
        const SizedBox(height: 14),
        if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 4)],
        Text(title, style: ds(32, c: UC.ink)),
      ],
    ),
  );
}

/// iOS style segmented control with a sliding white thumb.
class SlideSegmented extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  final double height;
  const SlideSegmented({super.key, required this.items, required this.value, required this.onChanged, this.height = 44});
  @override
  Widget build(BuildContext context) {
    final i = items.indexOf(value).clamp(0, items.length - 1);
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: UC.ink.withValues(alpha: .06), borderRadius: BorderRadius.circular(99)),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: w * i,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: UC.card,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [BoxShadow(color: UC.inkA(.10), blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final it in items)
                    Expanded(
                      child: Pressable(
                        onTap: () => onChanged(it),
                        scale: .94,
                        label: it,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: ts(14, w: FontWeight.w800, c: it == value ? UC.ink : UC.muted),
                            child: Text(it, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Grouped list section (iOS Settings style): white rounded block with hairline separators.
class GroupedList extends StatelessWidget {
  final List<Widget> children;
  const GroupedList({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.symmetric(vertical: 6),
    radius: 26,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[children[i], if (i < children.length - 1) Divider(height: 1, indent: 68, endIndent: 16, color: UC.line)],
      ],
    ),
  );
}

class GroupedRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String meta;
  final VoidCallback? onTap;
  final bool chevron;
  const GroupedRow({super.key, required this.icon, required this.title, this.tint = UC.deep, this.meta = '', this.onTap, this.chevron = true});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .985,
    label: title,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: tint, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: ts(15.5, w: FontWeight.w700)),
          ),
          if (meta.isNotEmpty)
            Text(
              meta,
              style: ts(13.5, w: FontWeight.w600, c: UC.muted),
            ),
          if (chevron)
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right_rounded, color: UC.muted, size: 22),
            ),
        ],
      ),
    ),
  );
}

/// Decoration for a white content block with the soft shadow used across the app.
BoxDecoration softBox([double r = 24, Color? c]) => BoxDecoration(
  color: c ?? UC.card,
  borderRadius: BorderRadius.circular(r),
  boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 10))],
);
