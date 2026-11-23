import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../theme.dart';

class CoinDot extends StatelessWidget {
  final double size;
  const CoinDot({super.key, this.size = 18});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: UC.coinGradient,
          border: Border.all(color: Colors.white.withValues(alpha: .45), width: size / 7),
        ),
      );
}

class DiamondIcon extends StatelessWidget {
  final double size;
  const DiamondIcon({super.key, this.size = 16});
  @override
  Widget build(BuildContext context) => Icon(Icons.diamond_rounded, size: size, color: const Color(0xFF7FD4FF));
}

class LiveBadge extends StatefulWidget {
  final double scale;
  const LiveBadge({super.key, this.scale = 1});
  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Container(
      height: 20 * s,
      padding: EdgeInsets.symmetric(horizontal: 7 * s),
      decoration: BoxDecoration(color: UC.primary, borderRadius: BorderRadius.circular(6 * s)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        FadeTransition(
          opacity: Tween(begin: 1.0, end: .35).animate(c),
          child: Container(width: 5 * s, height: 5 * s, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
        SizedBox(width: 4 * s),
        Text('LIVE', style: ts(10 * s, w: FontWeight.w800, c: Colors.white, ls: 1)),
      ]),
    );
  }
}

class Avatar extends StatelessWidget {
  final String? img;
  final String name;
  final double size;
  final Color? border;
  final double borderW;
  const Avatar({super.key, this.img, this.name = '', this.size = 36, this.border, this.borderW = 2});
  @override
  Widget build(BuildContext context) {
    final inner = (img != null && img!.isNotEmpty)
        ? Image.asset(img!, fit: BoxFit.cover, width: size, height: size)
        : Container(
            color: UC.deep,
            alignment: Alignment.center,
            child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: ts(size * .42, w: FontWeight.w800, c: Colors.white)),
          );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border!, width: borderW),
      ),
      child: ClipOval(child: inner),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color fg;
  final double height;
  final IconData? icon;
  const PrimaryButton(this.label,
      {super.key, this.onTap, this.color = UC.primary, this.fg = Colors.white, this.height = 54, this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: fg,
            disabledBackgroundColor: color.withValues(alpha: .45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
            textStyle: ts(16, w: FontWeight.w800),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
}

class ChoiceChipX extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  final bool pill;
  const ChoiceChipX(this.label, {super.key, required this.on, required this.onTap, this.pill = true});
  @override
  Widget build(BuildContext context) => Material(
        color: on ? UC.soft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pill ? 99 : 12),
          side: BorderSide(color: on ? UC.primary : UC.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(pill ? 99 : 12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(label, style: ts(13, w: FontWeight.w800, c: on ? UC.deep : UC.ink)),
          ),
        ),
      );
}

/// Segmented tabs on a soft background (Phone/Email, Activity/Messages...).
class Segmented extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  final Color bg;
  const Segmented({super.key, required this.items, required this.value, required this.onChanged, this.bg = UC.surface});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final i in items)
              GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == value ? [BoxShadow(color: UC.inkA(.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                  ),
                  child: Text(i, style: ts(13, w: FontWeight.w800, c: i == value ? UC.ink : UC.muted)),
                ),
              ),
          ],
        ),
      );
}

/// Labelled text field used in login/register.
class FieldBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focus;
  final String hint;
  final bool obscure;
  final TextInputType? type;
  final Widget? prefix;
  final Widget? suffix;
  final bool error;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  const FieldBox({
    super.key,
    required this.label,
    required this.controller,
    this.focus,
    this.hint = '',
    this.obscure = false,
    this.type,
    this.prefix,
    this.suffix,
    this.error = false,
    this.maxLength,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final focused = focus?.hasFocus ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: ts(12.5, w: FontWeight.w800, c: UC.muted)),
      const SizedBox(height: 6),
      AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: error ? UC.red : (focused ? UC.primary : UC.line), width: focused || error ? 2 : 1.5),
        ),
        child: Row(children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              obscureText: obscure,
              keyboardType: type,
              maxLength: maxLength,
              onChanged: onChanged,
              style: ts(15, w: FontWeight.w700, c: UC.ink),
              cursorColor: UC.primary,
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                hintStyle: ts(15, w: FontWeight.w600, c: UC.muted.withValues(alpha: .6)),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ]),
      ),
    ]);
  }
}

class CoinPill extends StatelessWidget {
  final int amount;
  final VoidCallback? onTap;
  final bool plus;
  const CoinPill(this.amount, {super.key, this.onTap, this.plus = true});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: EdgeInsets.only(left: 8, right: plus ? 5 : 12),
          decoration: BoxDecoration(color: UC.accentSoft, borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const CoinDot(size: 20),
            const SizedBox(width: 6),
            Text(fmtIn(amount), style: ts(14, w: FontWeight.w800, c: UC.accentText)),
            if (plus) ...[
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: UC.primary, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              ),
            ],
          ]),
        ),
      );
}

/// A back button + title row used by inner screens.
class TopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Color fg;
  const TopBar(this.title, {super.key, this.actions = const [], this.fg = UC.ink});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
        child: Row(children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back_rounded, color: fg),
          ),
          Expanded(child: Text(title, style: ts(20, w: FontWeight.w800, c: fg, ls: -0.5))),
          ...actions,
        ]),
      );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}
