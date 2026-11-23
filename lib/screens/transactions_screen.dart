import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'wallet_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String f = 'All';
  static const map = {'All': null, 'Recharges': 'rc', 'Gifts sent': 'gs', 'Received': 'gr', 'Withdrawals': 'wd'};

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final list = demoTx.where((t) => map[f] == null || t.kind == map[f]).toList();
    final days = <String>[];
    for (final t in list) {
      if (!days.contains(t.day)) days.add(t.day);
    }
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: pad.top),
          const TopBar('Transactions'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _sum('Coins in', '+18,640', UC.greenText)),
                const SizedBox(width: 8),
                Expanded(child: _sum('Coins out', '−9,215', UC.ink)),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              children: [
                for (final k in map.keys)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChipX(k, on: k == f, onTap: () => setState(() => f = k)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'Nothing here this month.',
                      style: ts(14, w: FontWeight.w700, c: UC.muted),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, pad.bottom + 16),
                    children: [
                      for (final d in days) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 8, 0, 6),
                          child: Text(
                            d,
                            style: ts(13, w: FontWeight.w800, c: UC.muted),
                          ),
                        ),
                        for (final t in list.where((t) => t.day == d)) txRow(t),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sum(String l, String v, Color c) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$l · Nov 2026',
          style: ts(11.5, w: FontWeight.w700, c: UC.muted),
        ),
        const SizedBox(height: 2),
        Text(
          v,
          style: ts(20, w: FontWeight.w800, c: c),
        ),
      ],
    ),
  );
}
