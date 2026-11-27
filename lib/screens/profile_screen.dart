import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return AuroraBg(
      child: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final st = AppState.I;
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, pad.top + 8, 16, pad.bottom + 30),
            children: staggerAll([
              Row(
                children: [
                  const Spacer(),
                  GlassCircle(Icons.settings_rounded, label: 'Settings', onTap: () => Navigator.pushNamed(context, '/server')),
                ],
              ),
              Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(colors: [UC.primary, UC.accent, UC.gold, UC.primary]),
                          boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .25), blurRadius: 30, offset: const Offset(0, 12))],
                        ),
                        child: const Avatar(img: 'assets/img/me.jpg', size: 104, border: Colors.white, borderW: 3),
                      ),
                      Positioned(
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: UC.ink,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            'Lv ${st.level}',
                            style: ts(12, w: FontWeight.w800, c: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(st.name, style: ds(30)),
                  const SizedBox(height: 4),
                  Text(
                    '@${st.username} · ID ${st.displayId}',
                    style: ts(14, w: FontWeight.w600, c: UC.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [for (final i in st.interests.take(3)) _tag(i, Colors.white, UC.deep), _tag('VIP 2', UC.ink, UC.gold)],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _count('182', 'Following'),
                      const VerticalDivider(width: 1, color: UC.line),
                      _count('12.4K', 'Fans'),
                      const VerticalDivider(width: 1, color: UC.line),
                      _count('98K', 'Likes'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Eyebrow('Your level'),
                        const Spacer(),
                        Text(
                          '${fmtIn(st.xp)} / 3,000 XP',
                          style: ts(13, w: FontWeight.w700, c: UC.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Level ${st.level}', style: ds(26)),
                    const SizedBox(height: 12),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(color: UC.ink.withValues(alpha: .06), borderRadius: BorderRadius.circular(99)),
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: (st.xp / 3000).clamp(0, 1)),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            decoration: BoxDecoration(gradient: UC.brandGradient, borderRadius: BorderRadius.circular(99)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Send ${(3000 - st.xp).clamp(0, 3000) ~/ 10} more coins of gifts to unlock an entry effect.',
                      style: ts(13.5, w: FontWeight.w500, c: UC.muted, h: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _money('Coins', fmtIn(st.coins), const CoinDot(size: 22), UC.accent, () => Navigator.pushNamed(context, '/coins'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _money(
                      'Diamonds',
                      fmtIn(st.diamonds),
                      const DiamondIcon(size: 22),
                      const Color(0xFF7FD4FF),
                      () => Navigator.pushNamed(context, '/withdraw'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GroupedList(
                children: [
                  GroupedRow(icon: Icons.videocam_rounded, tint: UC.primary, title: 'Go live now', onTap: () => Navigator.pushNamed(context, '/golive')),
                  GroupedRow(
                    icon: Icons.cloud_rounded,
                    tint: const Color(0xFF3B6FE0),
                    title: 'Live server',
                    meta: st.serverConfigured ? 'Connected' : 'Demo mode',
                    onTap: () => Navigator.pushNamed(context, '/server'),
                  ),
                  GroupedRow(icon: Icons.mail_rounded, tint: UC.deep, title: 'Inbox', meta: '3 new', onTap: () => Navigator.pushNamed(context, '/inbox')),
                ],
              ),
              const SizedBox(height: 12),
              GroupedList(
                children: [
                  GroupedRow(
                    icon: Icons.card_giftcard_rounded,
                    tint: UC.accentText,
                    title: 'Gift wall',
                    meta: '41 types',
                    onTap: () => toast(context, 'Gift wall coming soon'),
                  ),
                  GroupedRow(
                    icon: Icons.groups_rounded,
                    tint: const Color(0xFF12A15F),
                    title: 'Fan club',
                    meta: '312',
                    onTap: () => toast(context, 'Fan club coming soon'),
                  ),
                  GroupedRow(
                    icon: Icons.shield_rounded,
                    tint: const Color(0xFF0E9C9B),
                    title: 'Privacy & safety',
                    onTap: () => toast(context, 'Privacy settings coming soon'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GroupedList(
                children: [
                  GroupedRow(
                    icon: Icons.logout_rounded,
                    tint: UC.red,
                    title: 'Log out',
                    chevron: false,
                    onTap: () {
                      st.logout();
                      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                    },
                  ),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _tag(String t, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
      boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .08), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Text(
      t,
      style: ts(13, w: FontWeight.w700, c: fg),
    ),
  );

  Widget _count(String v, String l) => Expanded(
    child: Column(
      children: [
        Text(v, style: ds(24)),
        const SizedBox(height: 2),
        Text(
          l,
          style: ts(13, w: FontWeight.w600, c: UC.muted),
        ),
      ],
    ),
  );

  Widget _money(String l, String v, Widget icon, Color tint, VoidCallback onTap) => SoftCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tint.withValues(alpha: .15), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: icon,
            ),
            const Spacer(),
            const Icon(Icons.arrow_outward_rounded, size: 20, color: UC.muted),
          ],
        ),
        const SizedBox(height: 12),
        Text(v, style: ds(24)),
        Text(
          l,
          style: ts(13, w: FontWeight.w600, c: UC.muted),
        ),
      ],
    ),
  );
}
