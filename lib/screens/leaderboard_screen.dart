import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String kind = 'Hosts', per = 'Daily';

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final ranks = kind == 'Hosts'
        ? demoRanks
        : demoRanks.reversed.toList().asMap().entries.map((e) => Ranked(e.key + 1, e.value.name, e.value.img, e.value.lv, e.value.score)).toList();
    final podium = [ranks[1], ranks[0], ranks[2]];
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: staggerAll([
            Container(
              padding: EdgeInsets.fromLTRB(12, pad.top + 12, 12, 0),
              decoration: const BoxDecoration(
                color: UC.soft,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Leaderboard', style: ds(24, ls: -0.8))),
                      Segmented(items: const ['Hosts', 'Gifters'], value: kind, bg: Colors.white, onChanged: (v) => setState(() => kind = v)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final p in ['Daily', 'Weekly', 'Monthly'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => per = p),
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: p == per ? UC.ink : Colors.white, borderRadius: BorderRadius.circular(99)),
                              child: Text(
                                p,
                                style: ts(12.5, w: FontWeight.w800, c: p == per ? Colors.white : UC.ink),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        'Resets in 06:12:40',
                        style: ts(12, w: FontWeight.w700, c: UC.deep),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: _pod(podium[i], [58.0, 82.0, 44.0][i], [62.0, 76.0, 62.0][i], [const Color(0xFFD9D2DC), UC.gold, const Color(0xFFE0A27A)][i]),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
              child: Column(
                children: [
                  for (final r in ranks.skip(3))
                    Container(
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${r.rank}',
                              style: ts(14, w: FontWeight.w800, c: UC.muted),
                            ),
                          ),
                          Avatar(img: r.img, size: 38),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: ts(14, w: FontWeight.w800)),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: UC.primary, borderRadius: BorderRadius.circular(5)),
                                  child: Text(
                                    'Lv ${r.lv}',
                                    style: ts(10, w: FontWeight.w800, c: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const CoinDot(size: 13),
                          const SizedBox(width: 4),
                          Text(
                            r.score,
                            style: ts(13.5, w: FontWeight.w800, c: UC.accentText),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: UC.ink, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Text(
                  '#128',
                  style: ts(14, w: FontWeight.w800, c: Colors.white.withValues(alpha: .8)),
                ),
                const SizedBox(width: 10),
                const Avatar(img: 'assets/img/me.jpg', size: 36, border: UC.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: ts(14, w: FontWeight.w800, c: Colors.white),
                      ),
                      Text(
                        '2,140 coins to reach top 100',
                        style: ts(11.5, w: FontWeight.w600, c: Colors.white.withValues(alpha: .8)),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: UC.primary, borderRadius: BorderRadius.circular(11)),
                  child: Text(
                    'Climb',
                    style: ts(12.5, w: FontWeight.w800, c: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pod(Ranked r, double h, double size, Color medal) => Column(
    children: [
      Icon(Icons.workspace_premium_rounded, color: medal, size: 26),
      Avatar(img: r.img, size: size, border: medal, borderW: 3),
      const SizedBox(height: 4),
      Text(r.name, style: ts(13, w: FontWeight.w800)),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinDot(size: 11),
          const SizedBox(width: 3),
          Text(
            r.score,
            style: ts(12, w: FontWeight.w800, c: UC.accentText),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Container(
        height: h,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.only(top: 6),
        alignment: Alignment.topCenter,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Text('${r.rank}', style: ds(22, c: UC.primary)),
      ),
    ],
  );
}
