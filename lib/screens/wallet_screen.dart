import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final st = AppState.I;
        return ListView(
          padding: EdgeInsets.fromLTRB(12, pad.top + 12, 12, 20),
          children: staggerAll([
            Text('Wallet', style: ds(24, ls: -0.8)),
            const SizedBox(height: 12),
            // coins card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UC.accent, Color(0xFFFFB79E)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coin balance · for gifts',
                    style: ts(12.5, w: FontWeight.w800, c: UC.ink.withValues(alpha: .7)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const CoinDot(size: 30),
                      const SizedBox(width: 8),
                      Text(fmtIn(st.coins), style: ds(34, c: UC.ink, ls: -1)),
                    ],
                  ),
                  Text(
                    'Spent this week: 3,180 coins',
                    style: ts(12.5, w: FontWeight.w700, c: UC.ink.withValues(alpha: .7)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _btn('Recharge', UC.ink, Colors.white, () => Navigator.pushNamed(context, '/coins'))),
                      const SizedBox(width: 8),
                      Expanded(child: _btn('History', Colors.white.withValues(alpha: .6), UC.ink, () => Navigator.pushNamed(context, '/transactions'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // diamonds card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: UC.deep, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diamonds · your earnings',
                          style: ts(12.5, w: FontWeight.w800, c: Colors.white.withValues(alpha: .75)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const DiamondIcon(size: 24),
                            const SizedBox(width: 6),
                            Text(fmtIn(st.diamonds), style: ds(28, c: Colors.white, ls: -1)),
                          ],
                        ),
                        Text(
                          '≈ ₹${fmtIn(st.diamonds ~/ 10)}',
                          style: ts(13, w: FontWeight.w700, c: UC.gold),
                        ),
                      ],
                    ),
                  ),
                  _btn('Withdraw', Colors.white, UC.deep, () => Navigator.pushNamed(context, '/withdraw'), w: 124),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Daily check-in', style: ts(16, w: FontWeight.w800)),
                const Spacer(),
                Text(
                  'Day 4 streak',
                  style: ts(12.5, w: FontWeight.w800, c: UC.accentText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < 7; i++) Expanded(child: _day(i + 1, [5, 5, 10, 10, 20, 20, 50][i], st)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Recent', style: ts(16, w: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/transactions'),
                  child: Text(
                    'See all',
                    style: ts(13, w: FontWeight.w800, c: UC.deep),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final t in demoTx.take(4)) txRow(t),
          ]),
        );
      },
    );
  }

  Widget _btn(String l, Color bg, Color fg, VoidCallback onTap, {double? w}) => SizedBox(
    width: w,
    height: 42,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        l,
        style: ts(14, w: FontWeight.w800, c: fg),
      ),
    ),
  );

  Widget _day(int d, int amt, AppState st) {
    final past = d < 4 || (d == 4 && st.checkedInToday);
    final today = d == 4 && !st.checkedInToday;
    return GestureDetector(
      onTap: today ? st.checkIn : null,
      child: Container(
        height: 74,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: today
              ? UC.accent
              : past
              ? UC.accentSoft
              : UC.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Day $d',
              style: ts(
                10,
                w: FontWeight.w800,
                c: today
                    ? UC.ink
                    : past
                    ? UC.accentText
                    : UC.muted,
              ),
            ),
            const SizedBox(height: 4),
            past ? const Icon(Icons.check_circle_rounded, size: 20, color: UC.accentText) : const CoinDot(size: 20),
            const SizedBox(height: 4),
            Text(
              '+$amt',
              style: ts(
                11,
                w: FontWeight.w800,
                c: today
                    ? UC.ink
                    : past
                    ? UC.accentText
                    : UC.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget txRow(Tx t) {
  final k = switch (t.kind) {
    'rc' => ('UPI', UC.greenSoft, UC.greenText, UC.greenText),
    'gs' => ('GIFT', UC.soft, UC.deep, UC.ink),
    'gr' => ('GEM', const Color(0xFFE3F5FF), const Color(0xFF1A6E99), UC.greenText),
    'wd' => ('BANK', UC.surface, UC.ink, UC.ink),
    _ => ('FREE', UC.accentSoft, UC.accentText, UC.greenText),
  };
  return Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: UC.line),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: k.$2, borderRadius: BorderRadius.circular(13)),
          child: Text(
            k.$1,
            style: ts(10, w: FontWeight.w800, c: k.$3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(13.5, w: FontWeight.w800),
              ),
              Text(
                t.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(11.5, w: FontWeight.w600, c: UC.muted),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              t.amt,
              style: ts(14, w: FontWeight.w800, c: k.$4),
            ),
            Text(
              t.status,
              style: ts(11, w: FontWeight.w700, c: t.status == 'Processing' ? UC.accentText : UC.muted),
            ),
          ],
        ),
      ],
    ),
  );
}
