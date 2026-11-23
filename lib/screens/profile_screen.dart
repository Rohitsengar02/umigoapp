import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final st = AppState.I;
        return ListView(padding: EdgeInsets.zero, children: [
          Container(
            padding: EdgeInsets.fromLTRB(12, pad.top + 12, 12, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UC.soft, UC.accentSoft]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(children: [
              Row(children: [
                const Spacer(),
                IconButton(onPressed: () => Navigator.pushNamed(context, '/server'), tooltip: 'Settings', icon: const Icon(Icons.settings_outlined)),
              ]),
              Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                const Avatar(img: 'assets/img/me.jpg', size: 92, border: UC.primary, borderW: 3),
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: UC.primary, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
                    child: Text('Lv ${st.level}', style: ts(11, w: FontWeight.w800, c: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Text(st.name, style: ts(22, w: FontWeight.w800, ls: -0.5)),
              Text('@${st.username} · ID ${st.displayId}', style: ts(13, w: FontWeight.w600, c: UC.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, alignment: WrapAlignment.center, children: [
                for (final i in st.interests.take(2)) _tag(i, Colors.white, UC.deep),
                _tag('VIP 2', UC.ink, UC.gold),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _count('182', 'Following'),
                _count('12.4K', 'Fans'),
                _count('98K', 'Likes'),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Level ${st.level}', style: ts(14, w: FontWeight.w800)),
                    const Spacer(),
                    Text('${fmtIn(st.xp)} / 3,000 XP', style: ts(12.5, w: FontWeight.w700, c: UC.muted)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: (st.xp / 3000).clamp(0, 1), minHeight: 8, color: UC.primary, backgroundColor: UC.line),
                  ),
                  const SizedBox(height: 8),
                  Text('Send ${(3000 - st.xp).clamp(0, 3000) ~/ 10} more coins of gifts to unlock an entry effect.', style: ts(12, w: FontWeight.w600, c: UC.muted)),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _money('Coins', fmtIn(st.coins), const CoinDot(size: 18), () => Navigator.pushNamed(context, '/coins'))),
                const SizedBox(width: 8),
                Expanded(child: _money('Diamonds earned', fmtIn(st.diamonds), const DiamondIcon(size: 18), () => Navigator.pushNamed(context, '/withdraw'))),
              ]),
              const SizedBox(height: 8),
              _menu(context, Icons.videocam_rounded, 'Go live now', '', () => Navigator.pushNamed(context, '/golive')),
              _menu(context, Icons.cloud_rounded, 'Live server', st.serverConfigured ? 'Connected' : 'Demo mode', () => Navigator.pushNamed(context, '/server')),
              _menu(context, Icons.card_giftcard_rounded, 'Gift wall', '41 types', () => toast(context, 'Gift wall coming soon')),
              _menu(context, Icons.groups_rounded, 'Fan club', '312', () => toast(context, 'Fan club coming soon')),
              _menu(context, Icons.mail_outline_rounded, 'Inbox', '3 new', () => Navigator.pushNamed(context, '/inbox')),
              _menu(context, Icons.shield_outlined, 'Privacy & safety', '', () => toast(context, 'Privacy settings coming soon')),
              _menu(context, Icons.logout_rounded, 'Log out', '', () {
                st.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              }),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _tag(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: ts(12, w: FontWeight.w800, c: fg)),
      );

  Widget _count(String v, String l) => Expanded(
        child: Column(children: [
          Text(v, style: ts(18, w: FontWeight.w800)),
          Text(l, style: ts(12, w: FontWeight.w600, c: UC.muted)),
        ]),
      );

  Widget _money(String l, String v, Widget icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: UC.line, width: 1.5), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: ts(12, w: FontWeight.w700, c: UC.muted)),
            const SizedBox(height: 4),
            Row(children: [icon, const SizedBox(width: 6), Text(v, style: ts(18, w: FontWeight.w800))]),
          ]),
        ),
      );

  Widget _menu(BuildContext context, IconData i, String l, String meta, VoidCallback onTap) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: UC.soft, borderRadius: BorderRadius.circular(12)),
          child: Icon(i, color: UC.deep, size: 20),
        ),
        title: Text(l, style: ts(14.5, w: FontWeight.w800)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(meta, style: ts(12.5, w: FontWeight.w700, c: UC.muted)),
          const Icon(Icons.chevron_right_rounded, color: UC.muted),
        ]),
      );
}
