import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

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
    return AuroraBg(
      colors: [UC.peach, UC.lilac, UC.blush],
      child: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, pad.top + 64, 16, pad.bottom + 110),
            children: staggerAll([
              const Eyebrow('Resets in 06:12:40'),
              const SizedBox(height: 4),
              const HeroTitle('Top ', 'stars', size: 36),
              const SizedBox(height: 16),
              SlideSegmented(items: const ['Hosts', 'Gifters'], value: kind, onChanged: (v) => setState(() => kind = v)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final p in ['Daily', 'Weekly', 'Monthly'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChipX(p, on: p == per, onTap: () => setState(() => per = p)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: _pod(podium[i], [70.0, 100.0, 54.0][i], [64.0, 80.0, 64.0][i], [const Color(0xFFC9C1CF), UC.gold, const Color(0xFFE0A27A)][i]),
                    ),
                ],
              ),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final r in ranks.skip(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${r.rank}', style: ds(17, c: UC.muted)),
                            ),
                            Avatar(img: r.img, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: ts(15, w: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Level ${r.lv}',
                                    style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                  ),
                                ],
                              ),
                            ),
                            const CoinDot(size: 16),
                            const SizedBox(width: 5),
                            Text(
                              r.score,
                              style: ts(14.5, w: FontWeight.w800, c: UC.accentText),
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
            left: 16,
            right: 16,
            bottom: pad.bottom + 14,
            child: Glass(
              tint: const Color(0xE62E1C30),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Text('#128', style: ds(17, c: Colors.white.withValues(alpha: .8))),
                  const SizedBox(width: 10),
                  const Avatar(img: 'assets/img/me.jpg', size: 40, border: UC.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You',
                          style: ts(15, w: FontWeight.w800, c: Colors.white),
                        ),
                        Text(
                          '2,140 coins to reach top 100',
                          style: ts(12, w: FontWeight.w600, c: Colors.white.withValues(alpha: .75)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: UC.brandGradient, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      'Climb',
                      style: ts(14, w: FontWeight.w800, c: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pod(Ranked r, double h, double size, Color medal) => Column(
    children: [
      Icon(Icons.workspace_premium_rounded, color: medal, size: 26),
      Avatar(img: r.img, size: size, border: medal, borderW: 3),
      const SizedBox(height: 4),
      const SizedBox(height: 6),
      Text(r.name, style: ts(14, w: FontWeight.w800)),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [UC.card, UC.card.withValues(alpha: .3)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Text('${r.rank}', style: ds(28, c: medal == UC.gold ? UC.accentText : UC.deep)),
      ),
    ],
  );
}
