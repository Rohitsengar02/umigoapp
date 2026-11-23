import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class BuyCoinsScreen extends StatefulWidget {
  const BuyCoinsScreen({super.key});
  @override
  State<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  int pick = 3;
  String method = 'upi';
  int? added;

  static const methods = [
    ('upi', 'UPI', 'UPI', 'GPay, PhonePe, Paytm', UC.greenSoft, UC.greenText),
    ('play', 'GP', 'Google Play', 'Billed to your Play account', Color(0xFFE8F0FE), Color(0xFF1A56C4)),
    ('card', 'CARD', 'Debit / credit card', 'Visa, Mastercard, RuPay', UC.soft, UC.deep),
    ('nb', 'NB', 'Net banking', 'All major banks', UC.surface, UC.ink),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final p = coinPacks[pick];
    return Scaffold(
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) => Column(
          children: [
            SizedBox(height: pad.top),
            TopBar('Buy coins', actions: [CoinPill(AppState.I.coins, plus: false)]),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [UC.primary, UC.accent]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'First recharge: +50% coins',
                                style: ts(15, w: FontWeight.w800, c: Colors.white),
                              ),
                              Text(
                                'Ends in 23:41:07 · one time only',
                                style: ts(12, w: FontWeight.w700, c: Colors.white.withValues(alpha: .9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: .82,
                    children: [for (var i = 0; i < coinPacks.length; i++) _pack(i)],
                  ),
                  const SizedBox(height: 12),
                  Text('Pay with', style: ts(15, w: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (final m in methods)
                    GestureDetector(
                      onTap: () => setState(() => method = m.$1),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: method == m.$1 ? UC.primary : UC.line, width: method == m.$1 ? 2 : 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: m.$5, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                m.$2,
                                style: ts(10.5, w: FontWeight.w800, c: m.$6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.$3, style: ts(14, w: FontWeight.w800)),
                                  Text(
                                    m.$4,
                                    style: ts(12, w: FontWeight.w600, c: UC.muted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: method == m.$1 ? UC.primary : UC.line, width: 2),
                              ),
                              child: Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: method == m.$1 ? UC.primary : Colors.transparent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    "Coins are for gifts only and can't be refunded or cashed out.",
                    style: ts(11.5, w: FontWeight.w600, c: UC.muted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 6, 12, pad.bottom + 14),
              child: added != null
                  ? Column(
                      children: [
                        Text(
                          "+${fmtIn(added!)} coins! New balance ${fmtIn(AppState.I.coins)}. Go make someone's day.",
                          textAlign: TextAlign.center,
                          style: ts(13.5, w: FontWeight.w800, c: UC.greenText),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton('Done', onTap: () => Navigator.pop(context)),
                      ],
                    )
                  : PrimaryButton(
                      'Pay ₹${fmtIn(p.price)} · get ${fmtIn(p.coins + p.bonus)} coins',
                      onTap: () {
                        AppState.I.addCoins(p.coins + p.bonus);
                        setState(() => added = p.coins + p.bonus);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pack(int i) {
    final p = coinPacks[i];
    final on = i == pick;
    return GestureDetector(
      onTap: () => setState(() {
        pick = i;
        added = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: on ? UC.soft : UC.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? UC.primary : Colors.transparent, width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoinDot(size: 22 + i * 3.0),
                  const SizedBox(height: 6),
                  Text(fmtIn(p.coins), style: ts(16, w: FontWeight.w800)),
                  if (p.bonus > 0)
                    Text(
                      '+${fmtIn(p.bonus)} bonus',
                      style: ts(11, w: FontWeight.w800, c: UC.greenText),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${fmtIn(p.price)}',
                    style: ts(13, w: FontWeight.w800, c: UC.deep),
                  ),
                ],
              ),
            ),
            if (p.tag != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: UC.primary,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                    child: Text(
                      p.tag!,
                      style: ts(9, w: FontWeight.w800, c: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
