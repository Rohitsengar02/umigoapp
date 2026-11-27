import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';
import 'ui.dart';

/// One sheet for every coin payment: paid chat, private live entry, subscriptions.
/// Returns true when paid. The ledger is client-side until the backend lands.
Future<bool> showPaySheet(
  BuildContext context, {
  required String title,
  required String sub,
  required int price,
  required IconData icon,
  required bool Function() pay,
  String cta = 'Pay & unlock',
  String? img,
  List<String> perks = const [],
  String period = '',
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final pad = MediaQuery.paddingOf(ctx).bottom;
      final short = AppState.I.coins < price;
      return Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 18 + pad),
        decoration: BoxDecoration(color: UC.card, borderRadius: BorderRadius.circular(34)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: UC.ink.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)),
            ),
            const SizedBox(height: 20),
            Stack(
              clipBehavior: Clip.none,
              children: [
                img != null
                    ? Avatar(img: img, size: 78, border: Colors.white, borderW: 3)
                    : Container(
                        width: 78,
                        height: 78,
                        decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                        child: Icon(icon, color: Colors.white, size: 34),
                      ),
                if (img != null)
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: UC.brandGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: UC.card, width: 2.5),
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: ds(24, h: 1.1)),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: ts(14, w: FontWeight.w500, c: UC.muted, h: 1.4),
            ),
            if (perks.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final p in perks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: UC.greenSoft, shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, size: 15, color: UC.greenText),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p, style: ts(14, w: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const CoinDot(size: 26),
                  const SizedBox(width: 10),
                  Text(fmtIn(price), style: ds(26)),
                  if (period.isNotEmpty)
                    Text(
                      ' / $period',
                      style: ts(14, w: FontWeight.w700, c: UC.muted),
                    ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Your balance',
                        style: ts(11.5, w: FontWeight.w600, c: UC.muted),
                      ),
                      Text(
                        fmtIn(AppState.I.coins),
                        style: ts(14, w: FontWeight.w800, c: short ? UC.red : UC.ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (short)
              PrimaryButton(
                'Recharge coins',
                icon: Icons.add_rounded,
                onTap: () {
                  Navigator.pop(ctx, false);
                  Navigator.pushNamed(context, '/coins');
                },
              )
            else
              PrimaryButton(cta, icon: Icons.lock_open_rounded, onTap: () => Navigator.pop(ctx, pay())),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Not now',
                style: ts(14.5, w: FontWeight.w800, c: UC.muted),
              ),
            ),
          ],
        ),
      );
    },
  );
  return ok ?? false;
}

/// Sheet chrome shared by the smaller pickers.
Future<T?> showUmiSheet<T>(BuildContext context, Widget Function(BuildContext) child, {bool dark = false}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (ctx) => Container(
    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    padding: EdgeInsets.fromLTRB(18, 12, 18, 14 + MediaQuery.paddingOf(ctx).bottom),
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .82),
    decoration: BoxDecoration(color: dark ? const Color(0xF21E1420) : UC.card, borderRadius: BorderRadius.circular(32)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(color: (dark ? Colors.white : UC.ink).withValues(alpha: .16), borderRadius: BorderRadius.circular(9)),
          ),
        ),
        const SizedBox(height: 14),
        Flexible(child: child(ctx)),
      ],
    ),
  ),
);

/// Small "lock + price" badge for cards.
class AccessBadge extends StatelessWidget {
  final bool subscribers;
  final int price;
  const AccessBadge({super.key, required this.subscribers, this.price = 0});
  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: UC.inkA(.55), borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(subscribers ? Icons.workspace_premium_rounded : Icons.lock_rounded, size: 13, color: UC.gold),
        const SizedBox(width: 4),
        Text(
          subscribers ? 'Subscribers' : '$price',
          style: ts(11, w: FontWeight.w800, c: Colors.white),
        ),
        if (!subscribers) ...[const SizedBox(width: 3), const CoinDot(size: 11)],
      ],
    ),
  );
}

/// Glass pill used on photo surfaces.
class DarkChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  const DarkChip(this.text, {super.key, this.icon});
  @override
  Widget build(BuildContext context) => Glass(
    tint: const Color(0x33000000),
    shadow: false,
    radius: BorderRadius.circular(99),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 5)],
        Text(
          text,
          style: ts(12, w: FontWeight.w700, c: Colors.white),
        ),
      ],
    ),
  );
}
