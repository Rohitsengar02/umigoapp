import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});
  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  int amt = 2000;
  String method = 'upi';
  bool sent = false;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final st = AppState.I;
    final maxRs = st.diamonds ~/ 10;
    return Scaffold(
      body: AuroraBg(
        child: Column(
          children: [
            SizedBox(height: pad.top),
            const TopBar('Withdraw earnings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UC.deep, UC.violet]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available diamonds',
                          style: ts(12.5, w: FontWeight.w800, c: Colors.white.withValues(alpha: .75)),
                        ),
                        Row(
                          children: [
                            const DiamondIcon(size: 22),
                            const SizedBox(width: 6),
                            Text(fmtIn(st.diamonds), style: ds(28, c: Colors.white)),
                            const Spacer(),
                            Text(
                              '100 = ₹10',
                              style: ts(12, w: FontWeight.w700, c: UC.gold),
                            ),
                          ],
                        ),
                        Text(
                          '≈ ₹${fmtIn(maxRs)}',
                          style: ts(13, w: FontWeight.w700, c: Colors.white.withValues(alpha: .85)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: UC.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'KYC verified · PAN linked',
                              style: ts(12, w: FontWeight.w700, c: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount',
                    style: ts(13, w: FontWeight.w800, c: UC.muted),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹', style: ds(28, c: UC.muted)),
                      Text(fmtIn(amt), style: ts(40, w: FontWeight.w800, ls: -1)),
                      const SizedBox(width: 8),
                      Text(
                        '${fmtIn(amt * 10)} diamonds',
                        style: ts(13, w: FontWeight.w700, c: UC.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final q in [('₹500', 500), ('₹1,000', 1000), ('₹2,000', 2000), ('All', maxRs)])
                        ChoiceChipX(
                          q.$1,
                          on: amt == q.$2,
                          onTap: () => setState(() {
                            amt = q.$2;
                            sent = false;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Send to',
                    style: ts(13, w: FontWeight.w800, c: UC.muted),
                  ),
                  const SizedBox(height: 6),
                  for (final m in [
                    ('upi', 'UPI', 'UPI · aarav@okhdfc', 'Instant on most banks'),
                    ('bank', 'BANK', 'HDFC Bank ••• 2210', 'IMPS · within 24 hours'),
                  ])
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
                              decoration: softBox(18),
                              child: Text(
                                m.$2,
                                style: ts(10.5, w: FontWeight.w800, c: UC.deep),
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
                            Icon(
                              method == m.$1 ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: method == m.$1 ? UC.primary : UC.line,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _kv('Processing fee', '₹0'),
                  _kv('You receive', '₹${fmtIn(amt)}'),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 6, 12, pad.bottom + 14),
              child: Column(
                children: [
                  if (sent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Request sent · arrives in 24–48 hours',
                        style: ts(13.5, w: FontWeight.w800, c: UC.greenText),
                      ),
                    ),
                  PrimaryButton(
                    'Withdraw ₹${fmtIn(amt)}',
                    onTap: sent || amt < 100
                        ? null
                        : () {
                            if (st.withdraw(amt)) {
                              setState(() => sent = true);
                            } else {
                              toast(context, 'Not enough diamonds');
                            }
                          },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Minimum ₹100 · one withdrawal per day',
                    style: ts(11.5, w: FontWeight.w600, c: UC.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          k,
          style: ts(13.5, w: FontWeight.w700, c: UC.muted),
        ),
        const Spacer(),
        Text(v, style: ts(14, w: FontWeight.w800)),
      ],
    ),
  );
}
