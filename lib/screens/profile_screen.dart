import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../data/social_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/pay_sheet.dart';
import '../widgets/ui.dart';
import 'creator_profile_screen.dart';
import 'messages_screen.dart';
import 'reels_screen.dart';

const _myPhotos = [
  'assets/img/me.jpg',
  'assets/img/ava.jpg',
  'assets/img/beach.jpg',
  'assets/img/crew.jpg',
  'assets/img/kabir2.jpg',
  'assets/img/me.jpg',
  'assets/img/dev.jpg',
  'assets/img/ava.jpg',
  'assets/img/beach.jpg',
];

/// My profile, Instagram style: stats, bio, privacy, live timing, then a grid.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return AuroraBg(
      child: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final st = AppState.I;
          final saved = reels.where((r) => st.savedReels.contains(r.id)).toList();
          final mine = reels.take(6).toList();
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ...staggerSlivers([
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(70, pad.top + 8, 16, 0),
                    child: Row(
                      children: [
                        if (st.privateAccount) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock_rounded, size: 16)),
                        Flexible(
                          child: Text(
                            st.username,
                            overflow: TextOverflow.ellipsis,
                            style: ts(18, w: FontWeight.w800),
                          ),
                        ),
                        const Spacer(),
                        GlassCircle(Icons.add_box_outlined, label: 'Create', size: 42, onTap: () => _create(context)),
                        const SizedBox(width: 8),
                        GlassCircle(
                          Icons.menu_rounded,
                          label: 'Settings',
                          size: 42,
                          onTap: () => Navigator.push(context, umiRoute((_) => const SettingsScreen())),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          img: 'assets/img/me.jpg',
                          badge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: UC.ink,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: UC.card, width: 2),
                            ),
                            child: Text(
                              'Lv ${st.level}',
                              style: ts(11, w: FontWeight.w800, c: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const ProfileStat('48', 'Posts'),
                        const ProfileStat('12.4K', 'Followers'),
                        ProfileStat('${182 + st.following.length}', 'Following'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(st.name, style: ds(24))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(color: UC.pill, borderRadius: BorderRadius.circular(99)),
                              child: Text(
                                'VIP 2',
                                style: ts(11.5, w: FontWeight.w800, c: UC.gold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(st.bio, style: ts(14.5, w: FontWeight.w500, h: 1.4)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [for (final i in st.interests.take(3)) _tag(i)]),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(child: ProfileButton('Edit profile', onTap: () => _editBio(context))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ProfileButton('Wallet', icon: Icons.account_balance_wallet_rounded, onTap: () => Navigator.pushNamed(context, '/coins')),
                        ),
                        const SizedBox(width: 8),
                        Pressable(
                          label: 'Go live',
                          onTap: () => Navigator.pushNamed(context, '/golive'),
                          child: Container(
                            width: 46,
                            height: 42,
                            decoration: BoxDecoration(gradient: UC.brandGradient, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // privacy, live timing, prices
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      decoration: softBox(26),
                      child: Column(
                        children: [
                          const ThemeRow(),
                          const Divider(height: 1, indent: 70),
                          SwitchListTile.adaptive(
                            value: st.privateAccount,
                            onChanged: (v) => st.updateProfile(privateAccount: v),
                            activeTrackColor: UC.primary,
                            secondary: _ico(st.privateAccount ? Icons.lock_rounded : Icons.public_rounded, st.privateAccount ? UC.deep : UC.green),
                            title: Text(st.privateAccount ? 'Private account' : 'Public account', style: ts(14.5, w: FontWeight.w800)),
                            subtitle: Text(
                              st.privateAccount ? 'Only approved followers see your posts and reels' : 'Anyone can see your posts and reels',
                              style: ts(12.5, w: FontWeight.w500, c: UC.muted),
                            ),
                          ),
                          const Divider(height: 1, indent: 70),
                          _setting(Icons.event_rounded, UC.primary, 'Live timing', '${st.liveDays} · ${st.liveTime}', () => editLiveTiming(context)),
                          const Divider(height: 1, indent: 70),
                          _setting(
                            Icons.chat_bubble_rounded,
                            UC.accentText,
                            'Chat price',
                            st.myChatPrice == 0 ? 'Free' : '${st.myChatPrice} coins to open a chat',
                            () => editChatPrice(context),
                          ),
                          const Divider(height: 1, indent: 70),
                          _setting(
                            Icons.workspace_premium_rounded,
                            const Color(0xFF8E4FA0),
                            'Subscription',
                            '${st.mySubPrice} coins / month',
                            () => _editSub(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(child: _money('Coins', fmtIn(st.coins), const CoinDot(size: 20), UC.accent, () => Navigator.pushNamed(context, '/coins'))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _money(
                            'Diamonds',
                            fmtIn(st.diamonds),
                            const DiamondIcon(size: 20),
                            const Color(0xFF7FD4FF),
                            () => Navigator.pushNamed(context, '/withdraw'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              SliverPersistentHeader(
                pinned: true,
                delegate: ProfileTabsHeader(
                  icons: const [Icons.grid_on_rounded, Icons.slow_motion_video_rounded, Icons.sensors_rounded, Icons.bookmark_border_rounded],
                  index: tab,
                  onTap: (i) => setState(() => tab = i),
                ),
              ),
              if (tab == 0)
                photoGrid(_myPhotos, onTap: (_) {})
              else if (tab == 1)
                SliverPadding(
                  padding: const EdgeInsets.all(2),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: .62,
                    ),
                    itemCount: mine.length,
                    itemBuilder: (_, i) => ReelThumb(mine[i], onTap: () => openReels(context, mine, i)),
                  ),
                )
              else if (tab == 2)
                SliverToBoxAdapter(
                  child: PastLives(name: st.name, img: 'assets/img/me.jpg'),
                )
              else if (saved.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 40, color: UC.muted),
                        const SizedBox(height: 8),
                        Text(
                          'Reels you save show up here',
                          textAlign: TextAlign.center,
                          style: ts(14.5, w: FontWeight.w700, c: UC.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(2),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: .62,
                    ),
                    itemCount: saved.length,
                    itemBuilder: (_, i) => ReelThumb(saved[i], onTap: () => openReels(context, saved, i)),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: pad.bottom + 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _tag(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(color: UC.card, borderRadius: BorderRadius.circular(99)),
    child: Text(
      '#$t',
      style: ts(12.5, w: FontWeight.w700, c: UC.deep),
    ),
  );

  Widget _ico(IconData i, Color c) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)),
    child: Icon(i, color: c, size: 20),
  );

  Widget _setting(IconData i, Color c, String title, String meta, VoidCallback onTap) => ListTile(
    onTap: onTap,
    leading: _ico(i, c),
    title: Text(title, style: ts(14.5, w: FontWeight.w800)),
    subtitle: Text(
      meta,
      style: ts(12.5, w: FontWeight.w500, c: UC.muted),
    ),
    trailing: Icon(Icons.chevron_right_rounded, color: UC.muted),
  );

  Widget _money(String l, String v, Widget icon, Color tint, VoidCallback onTap) => SoftCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    radius: 24,
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: tint.withValues(alpha: .15), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v, style: ds(19)),
              Text(
                l,
                style: ts(12, w: FontWeight.w600, c: UC.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _create(BuildContext context) => showUmiSheet(
    context,
    (ctx) => GroupedList(
      children: [
        GroupedRow(
          icon: Icons.videocam_rounded,
          tint: UC.primary,
          title: 'Go live',
          onTap: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(context, '/golive');
          },
        ),
        GroupedRow(
          icon: Icons.slow_motion_video_rounded,
          tint: const Color(0xFF8E4FA0),
          title: 'New reel',
          onTap: () {
            Navigator.pop(ctx);
            toast(context, 'Reel uploads arrive with the backend');
          },
        ),
        GroupedRow(
          icon: Icons.photo_rounded,
          tint: UC.accentText,
          title: 'New post',
          onTap: () {
            Navigator.pop(ctx);
            toast(context, 'Photo posts arrive with the backend');
          },
        ),
      ],
    ),
  );

  void _editBio(BuildContext context) {
    final ctl = TextEditingController(text: AppState.I.bio);
    showUmiSheet(
      context,
      (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit profile', style: ds(24)),
            const SizedBox(height: 14),
            FieldBox(label: 'Bio', controller: ctl, hint: 'Tell fans what your lives are about', maxLength: 120),
            const SizedBox(height: 16),
            PrimaryButton(
              'Save',
              dark: true,
              onTap: () {
                AppState.I.updateProfile(bio: ctl.text.trim());
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editSub(BuildContext context) {
    var v = AppState.I.mySubPrice;
    showUmiSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Subscription price', style: ds(24)),
            const SizedBox(height: 4),
            Text(
              'Subscribers get your private lives, exclusive posts and free chat.',
              style: ts(13.5, w: FontWeight.w500, c: UC.muted, h: 1.4),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in [99, 149, 199, 299, 499, 999]) ChoiceChipX('$p / month', on: v == p, onTap: () => set(() => v = p)),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Save',
              dark: true,
              onTap: () {
                AppState.I.updateProfile(subPrice: v);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// When I usually go live, shown on my profile so fans can plan.
void editLiveTiming(BuildContext context) {
  final st = AppState.I;
  var days = st.liveDays;
  var time = st.liveTime;
  showUmiSheet(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Live timing', style: ds(24)),
          const SizedBox(height: 4),
          Text(
            'Shown on your profile. Followers get a reminder 10 minutes before.',
            style: ts(13.5, w: FontWeight.w500, c: UC.muted, h: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Days',
            style: ts(13, w: FontWeight.w800, c: UC.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in ['Daily', 'Mon–Fri', 'Weekends', 'Mon, Wed, Fri', 'Tue, Thu']) ChoiceChipX(d, on: d == days, onTap: () => set(() => days = d)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Time',
            style: ts(13, w: FontWeight.w800, c: UC.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in ['7:00 AM', '12:00 PM', '6:00 PM', '8:00 PM', '9:00 PM', '10:00 PM', '11:30 PM'])
                ChoiceChipX(t, on: t == time, onTap: () => set(() => time = t)),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            'Save',
            dark: true,
            onTap: () {
              st.updateProfile(liveDays: days, liveTime: time);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}

/// Settings: level, money, server, subscriptions, logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBg(
        child: ListenableBuilder(
          listenable: AppState.I,
          builder: (context, _) {
            final st = AppState.I;
            final subs = st.subscribed.map(creatorById).whereType<Creator>().toList();
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 0, 0, pad.bottom + 30),
              children: [
                const LargeTitle('Settings'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    children: staggerAll([
                      SoftCard(padding: EdgeInsets.zero, child: const ThemeRow()),
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
                      GroupedList(
                        children: [
                          GroupedRow(
                            icon: Icons.videocam_rounded,
                            tint: UC.primary,
                            title: 'Go live now',
                            onTap: () => Navigator.pushNamed(context, '/golive'),
                          ),
                          GroupedRow(
                            icon: Icons.account_balance_wallet_rounded,
                            tint: UC.accentText,
                            title: 'Buy coins',
                            meta: fmtIn(st.coins),
                            onTap: () => Navigator.pushNamed(context, '/coins'),
                          ),
                          GroupedRow(
                            icon: Icons.receipt_long_rounded,
                            tint: UC.deep,
                            title: 'Transactions',
                            onTap: () => Navigator.pushNamed(context, '/transactions'),
                          ),
                          GroupedRow(
                            icon: Icons.currency_rupee_rounded,
                            tint: UC.greenText,
                            title: 'Withdraw diamonds',
                            meta: fmtIn(st.diamonds),
                            onTap: () => Navigator.pushNamed(context, '/withdraw'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GroupedList(
                        children: [
                          GroupedRow(
                            icon: Icons.workspace_premium_rounded,
                            tint: const Color(0xFF8E4FA0),
                            title: 'My subscriptions',
                            meta: subs.isEmpty ? 'None' : '${subs.length}',
                            onTap: () => showUmiSheet(
                              context,
                              (ctx) => subs.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        'Subscribe to a creator from their profile.',
                                        textAlign: TextAlign.center,
                                        style: ts(14.5, w: FontWeight.w700, c: UC.muted),
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (final c in subs)
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Avatar(img: c.img, size: 44),
                                            title: Text(c.name, style: ts(15, w: FontWeight.w800)),
                                            subtitle: Text(
                                              '${c.subPrice} coins / month',
                                              style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                            ),
                                            trailing: TextButton(
                                              onPressed: () {
                                                st.unsubscribe(c.id);
                                                Navigator.pop(ctx);
                                              },
                                              child: Text(
                                                'Cancel',
                                                style: ts(13.5, w: FontWeight.w800, c: UC.red),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                          GroupedRow(
                            icon: Icons.mail_rounded,
                            tint: UC.deep,
                            title: 'Activity',
                            meta: '3 new',
                            onTap: () => Navigator.pushNamed(context, '/inbox'),
                          ),
                          GroupedRow(
                            icon: Icons.cloud_rounded,
                            tint: const Color(0xFF3B6FE0),
                            title: 'Live server',
                            meta: st.serverConfigured ? 'Connected' : 'Demo mode',
                            onTap: () => Navigator.pushNamed(context, '/server'),
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Light / dark choice. Saved on the phone and applied to every screen at once.
class ThemeRow extends StatelessWidget {
  const ThemeRow({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = AppState.I.darkMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: UC.violet.withValues(alpha: .14), borderRadius: BorderRadius.circular(13)),
            child: Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: dark ? UC.gold : UC.violet, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Theme', style: ts(14.5, w: FontWeight.w800)),
          ),
          SizedBox(
            width: 150,
            child: SlideSegmented(
              items: const ['Light', 'Dark'],
              value: dark ? 'Dark' : 'Light',
              height: 38,
              onChanged: (v) => AppState.I.setDarkMode(v == 'Dark'),
            ),
          ),
        ],
      ),
    );
  }
}
