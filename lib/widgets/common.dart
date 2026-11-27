import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import 'skeleton.dart';
import 'ui.dart';

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
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Container(
      height: 22 * s,
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      decoration: BoxDecoration(
        color: UC.primary,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .45), blurRadius: 10 * s, offset: Offset(0, 3 * s))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: .35).animate(c),
            child: Container(
              width: 5 * s,
              height: 5 * s,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: 4 * s),
          Text(
            'LIVE',
            style: ts(10 * s, w: FontWeight.w800, c: Colors.white, ls: 1),
          ),
        ],
      ),
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
        ? fadeInAsset(img!, w: size, h: size)
        : Container(
            color: UC.deep,
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: ts(size * .42, w: FontWeight.w800, c: Colors.white),
            ),
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

  /// true = dark ink pill with a rose icon disc (the calm "Continue" style).
  final bool dark;
  const PrimaryButton(this.label, {super.key, this.onTap, this.color = UC.primary, this.fg = Colors.white, this.height = 56, this.icon, this.dark = false});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final useGradient = !dark && color == UC.primary;
    final bg = dark ? UC.ink : color;
    return Pressable(
      onTap: onTap,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : .5,
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: useGradient ? null : bg,
            gradient: useGradient
                ? const LinearGradient(colors: [UC.primary, Color(0xFFE5677F), UC.accent], begin: Alignment.centerLeft, end: Alignment.centerRight)
                : dark
                ? const LinearGradient(colors: [UC.ink, Color(0xFF4A3550)], begin: Alignment.centerLeft, end: Alignment.centerRight)
                : null,
            borderRadius: BorderRadius.circular(99),
            boxShadow: enabled ? [BoxShadow(color: (dark ? UC.ink : bg).withValues(alpha: .28), blurRadius: 22, offset: const Offset(0, 10))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                dark
                    ? Container(
                        width: height * .62,
                        height: height * .62,
                        decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                        child: Icon(icon, size: height * .34, color: Colors.white),
                      )
                    : Icon(icon, size: 20, color: fg),
                SizedBox(width: dark ? 12 : 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: ts(height >= 50 ? 16.5 : 14.5, w: FontWeight.w800, c: dark ? Colors.white : fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChoiceChipX extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  final bool pill;
  const ChoiceChipX(this.label, {super.key, required this.on, required this.onTap, this.pill = true});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .94,
    label: label,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: on ? UC.ink : Colors.white,
        borderRadius: BorderRadius.circular(pill ? 99 : 14),
        border: Border.all(color: on ? UC.ink : Colors.white),
        boxShadow: [
          BoxShadow(
            color: (on ? UC.ink : const Color(0xFF6B4A6E)).withValues(alpha: on ? .22 : .07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: on
                ? const Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  )
                : const SizedBox.shrink(),
          ),
          Text(
            label,
            style: ts(14, w: FontWeight.w700, c: on ? Colors.white : UC.ink),
          ),
        ],
      ),
    ),
  );
}

/// Segmented tabs (Phone/Email, Activity/Messages...) with a sliding thumb.
class Segmented extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  final Color bg;
  final double? width;
  const Segmented({super.key, required this.items, required this.value, required this.onChanged, this.bg = UC.surface, this.width});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width ?? items.length * 124.0,
    child: SlideSegmented(items: items, value: value, onChanged: onChanged),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: ts(13, w: FontWeight.w700, c: UC.muted),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: error ? UC.red : (focused ? UC.primary : Colors.white), width: focused || error ? 1.8 : 1),
            boxShadow: [
              BoxShadow(
                color: focused ? UC.primary.withValues(alpha: .16) : const Color(0xFF6B4A6E).withValues(alpha: .07),
                blurRadius: focused ? 18 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focus,
                  obscureText: obscure,
                  keyboardType: type,
                  maxLength: maxLength,
                  onChanged: onChanged,
                  style: ts(16, w: FontWeight.w600, c: UC.ink),
                  cursorColor: UC.primary,
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: '',
                    hintStyle: ts(15, w: FontWeight.w600, c: UC.muted.withValues(alpha: .6)),
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

class CoinPill extends StatelessWidget {
  final int amount;
  final VoidCallback? onTap;
  final bool plus;
  const CoinPill(this.amount, {super.key, this.onTap, this.plus = true});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: '${fmtIn(amount)} coins',
    child: Container(
      height: 44,
      padding: EdgeInsets.only(left: 8, right: plus ? 6 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: UC.accent.withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinDot(size: 24),
          const SizedBox(width: 7),
          Text(
            fmtIn(amount),
            style: ts(15, w: FontWeight.w800, c: UC.accentText),
          ),
          if (plus) ...[
            const SizedBox(width: 7),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    ),
  );
}

/// A back button + title row used by inner screens.
class TopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Color fg;
  final bool back;
  const TopBar(this.title, {super.key, this.actions = const [], this.fg = UC.ink, this.back = true});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(back ? 14 : 20, 8, 12, 8),
    child: Row(
      children: [
        if (back) ...[
          fg == UC.ink
              ? GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context))
              : IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg),
                ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: back ? ds(22, c: fg) : ds(30, c: fg),
          ),
        ),
        ...actions,
      ],
    ),
  );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

/// Pushes a tab page (which has no back button of its own) as a full screen with one.
class WithBack extends StatelessWidget {
  final Widget child;
  const WithBack(this.child, {super.key});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 14,
            top: top + 8,
            child: GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
          ),
        ],
      ),
    );
  }
}
