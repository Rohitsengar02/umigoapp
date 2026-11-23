import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../live/live_session.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gift_icons.dart';

Future<void> showGiftSheet(BuildContext context, LiveSession s) => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: UC.inkA(.35),
      isScrollControlled: true,
      builder: (_) => GiftSheet(session: s),
    );

class GiftSheet extends StatefulWidget {
  final LiveSession session;
  const GiftSheet({super.key, required this.session});
  @override
  State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> {
  String tab = 'Popular';
  String pick = 'rocket';
  int qty = 1;
  String sent = '';

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    final g = giftById(pick);
    final total = g.price * qty;
    final short = total > st.coins;
    final pad = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: st,
      builder: (context, _) => Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, pad + 18),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: UC.line, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final t in ['Popular', 'Lucky', 'Luxury', 'Party', 'My bag'])
                GestureDetector(
                  onTap: () => setState(() => tab = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t == tab ? UC.soft : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                    child: Text(t, style: ts(13, w: FontWeight.w800, c: t == tab ? UC.deep : UC.muted)),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: .8,
            children: [
              for (final x in gifts)
                GestureDetector(
                  onTap: () => setState(() {
                    pick = x.id;
                    sent = '';
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: x.id == pick ? UC.soft : UC.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: x.id == pick ? UC.primary : Colors.transparent, width: 2),
                    ),
                    child: Stack(children: [
                      Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedScale(scale: x.id == pick ? 1.12 : 1, duration: const Duration(milliseconds: 160), child: GiftIcon(x.id, size: 42)),
                          const SizedBox(height: 3),
                          Text(x.name, style: ts(12, w: FontWeight.w800)),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const CoinDot(size: 11),
                            const SizedBox(width: 3),
                            Text(fmtIn(x.price), style: ts(11.5, w: FontWeight.w800, c: UC.accentText)),
                          ]),
                        ]),
                      ),
                      if (x.tag != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: UC.accent, borderRadius: BorderRadius.circular(5)),
                            child: Text(x.tag!, style: ts(9, w: FontWeight.w800, c: UC.ink)),
                          ),
                        ),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/coins'),
              child: Container(
                height: 36,
                padding: const EdgeInsets.only(left: 10, right: 5),
                decoration: BoxDecoration(color: UC.accentSoft, borderRadius: BorderRadius.circular(99)),
                child: Row(children: [
                  const CoinDot(size: 18),
                  const SizedBox(width: 6),
                  Text(fmtIn(st.coins), style: ts(14, w: FontWeight.w800, c: UC.accentText)),
                  const SizedBox(width: 6),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: UC.accent, borderRadius: BorderRadius.circular(99)),
                    child: Text('Top up', style: ts(12, w: FontWeight.w800, c: UC.ink)),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            for (final n in [1, 10, 99, 520])
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => setState(() {
                    qty = n;
                    sent = '';
                  }),
                  child: Container(
                    height: 32,
                    constraints: const BoxConstraints(minWidth: 38),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: n == qty ? UC.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: n == qty ? UC.primary : UC.line, width: 1.5),
                    ),
                    child: Text('×$n', style: ts(12.5, w: FontWeight.w800, c: n == qty ? Colors.white : UC.ink)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          if (short)
            PrimaryButton('Not enough coins · Recharge', color: UC.accent, fg: UC.ink, onTap: () => Navigator.pushNamed(context, '/coins'))
          else
            PrimaryButton(
              'Send ${g.name}${qty > 1 ? ' ×$qty' : ''} · ${fmtIn(total)} coins',
              onTap: () {
                if (widget.session.sendGift(g, qty)) {
                  setState(() => sent = 'Sent! ${widget.session.hostName} got ${fmtIn(total ~/ 2)} diamonds from you.');
                }
              },
            ),
          if (sent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(sent, textAlign: TextAlign.center, style: ts(13, w: FontWeight.w800, c: UC.greenText)),
          ],
        ]),
      ),
    );
  }
}
