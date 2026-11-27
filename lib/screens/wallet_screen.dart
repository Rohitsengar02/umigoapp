import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return AuroraBg(
      colors: const [UC.peach, UC.lilac, UC.blush],
      child: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final st = AppState.I;
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, pad.top + 64, 16, pad.bottom + 30),
            children: staggerAll([
              const Eyebrow('Your money'),
              const SizedBox(height: 4),
              const HeroTitle('Wallet', ''),
              const SizedBox(height: 16),
              // coins card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB38F), UC.accent, Color(0xFFFFC46B)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: UC.accent.withValues(alpha: .4), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Eyebrow('Coins · for gifts', color: UC.ink.withValues(alpha: .65)),
                        const Spacer(),
                        Icon(Icons.contactless_rounded, color: UC.ink.withValues(alpha: .5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CoinDot(size: 34),
                        const SizedBox(width: 10),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: st.coins.toDouble()),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => Text(fmtIn(v.round()), style: ds(42, c: UC.ink)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spent this week: 3,180 coins',
                      style: ts(13.5, w: FontWeight.w600, c: UC.ink.withValues(alpha: .7)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _btn('Recharge', UC.ink, Colors.white, Icons.add_rounded, () => Navigator.pushNamed(context, '/coins'))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _btn(
                            'History',
                            Colors.white.withValues(alpha: .55),
                            UC.ink,
                            Icons.receipt_long_rounded,
                            () => Navigator.pushNamed(context, '/transactions'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // diamonds card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UC.deep, UC.ink]),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: UC.deep.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow('Diamonds · earnings', color: Colors.white.withValues(alpha: .7)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const DiamondIcon(size: 26),
                              const SizedBox(width: 8),
                              Text(fmtIn(st.diamonds), style: ds(32, c: Colors.white)),
                            ],
                          ),
                          Text(
                            '≈ ₹${fmtIn(st.diamonds ~/ 10)}',
                            style: ts(14, w: FontWeight.w700, c: UC.gold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 128, child: _btn('Withdraw', Colors.white, UC.deep, Icons.south_rounded, () => Navigator.pushNamed(context, '/withdraw'))),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionHead(
                'Daily check-in',
                sub: 'Come back every day for more coins',
                trailing: Text(
                  'Day 4',
                  style: ts(14, w: FontWeight.w800, c: UC.accentText),
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++) Expanded(child: _day(i + 1, [5, 5, 10, 10, 20, 20, 50][i], st)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionHead('Recent', action: 'See all', onAction: () => Navigator.pushNamed(context, '/transactions')),
              const SizedBox(height: 12),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [for (final t in demoTx.take(4)) txRow(t)]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _btn(String l, Color bg, Color fg, IconData icon, VoidCallback onTap) => Pressable(
    onTap: onTap,
    label: l,
    child: Container(
      height: 46,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            l,
            style: ts(14.5, w: FontWeight.w800, c: fg),
          ),
        ],
      ),
    ),
  );

  Widget _day(int d, int amt, AppState st) {
    final past = d < 4 || (d == 4 && st.checkedInToday);
    final today = d == 4 && !st.checkedInToday;
    final fg = today
        ? Colors.white
        : past
        ? UC.accentText
        : UC.muted;
    return Pressable(
      onTap: today ? st.checkIn : null,
      label: 'Day $d, $amt coins',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 84,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: today ? UC.brandGradient : null,
          color: today
              ? null
              : past
              ? UC.accentSoft
              : UC.ink.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(99),
          boxShadow: today ? [BoxShadow(color: UC.primary.withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 5))] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'D$d',
              style: ts(11, w: FontWeight.w800, c: fg),
            ),
            const SizedBox(height: 6),
            past ? const Icon(Icons.check_circle_rounded, size: 20, color: UC.accentText) : const CoinDot(size: 20),
            const SizedBox(height: 6),
            Text(
              '+$amt',
              style: ts(11.5, w: FontWeight.w800, c: fg),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: k.$2, shape: BoxShape.circle),
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
