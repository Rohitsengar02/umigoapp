import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart' show fmtK;
import '../data/social_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/pay_sheet.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui.dart';
import 'chat_screen.dart';
import 'reels_screen.dart';

void openCreator(BuildContext context, String id) {
  final c = creatorById(id);
  if (c == null) return;
  Navigator.push(context, umiRoute((_) => CreatorProfileScreen(creator: c)));
}

/// Opens the paid subscription sheet for a creator.
Future<bool> subscribeTo(BuildContext context, Creator c) => showPaySheet(
  context,
  title: 'Subscribe to ${c.name.split(' ').first}',
  sub: 'Support ${c.name.split(' ').first} every month and get into the inner circle.',
  price: c.subPrice,
  period: 'month',
  icon: Icons.workspace_premium_rounded,
  img: c.img,
  cta: 'Subscribe',
  perks: const ['Subscriber-only private lives', 'Exclusive posts and reels', 'Free chat, no unlock fee', 'Subscriber badge in every live'],
  pay: () => AppState.I.subscribe(c.id, c.subPrice),
);

/// A chat is open when it is free, paid for, covered by a subscription, or the
/// creator already wrote to me.
bool chatOpen(Creator c) {
  final st = AppState.I;
  return c.chatPrice == 0 || st.isSubscribed(c.id) || st.isUnlocked('chat:${c.id}') || convos.any((v) => v.creatorId == c.id && v.msgs.any((m) => !m.mine));
}

/// Opens a chat, asking for the unlock fee first when the creator charges one.
Future<void> messageCreator(BuildContext context, Creator c) async {
  final st = AppState.I;
  if (!chatOpen(c)) {
    final ok = await showPaySheet(
      context,
      title: 'Chat with ${c.name.split(' ').first}',
      sub: '${c.name.split(' ').first} reads paid chats first. Pay once to open this chat, then message freely.',
      price: c.chatPrice,
      icon: Icons.chat_bubble_rounded,
      img: c.img,
      cta: 'Pay & start chatting',
      perks: const ['One-time unlock for this chat', 'Send photos, gifts and voice notes', 'Subscribers chat for free'],
      pay: () => st.unlock('chat:${c.id}', c.chatPrice),
    );
    if (!ok || !context.mounted) return;
  }
  Navigator.push(context, umiRoute((_) => ChatScreen(creator: c)));
}

class CreatorProfileScreen extends StatefulWidget {
  final Creator creator;
  const CreatorProfileScreen({super.key, required this.creator});
  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  int tab = 0;
  bool requested = false, remind = false;

  Creator get c => widget.creator;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBg(
        child: ListenableBuilder(
          listenable: AppState.I,
          builder: (context, _) {
            final st = AppState.I;
            final following = st.isFollowing(c.id);
            final subbed = st.isSubscribed(c.id);
            final locked = c.privateAccount && !following;
            final myReels = reels.where((r) => r.creatorId == c.id).toList();
            final reelList = [...myReels, ...reels.where((r) => r.creatorId != c.id)].take(9).toList();
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                ...staggerSlivers([
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, pad.top + 8, 16, 0),
                      child: Row(
                        children: [
                          GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (c.privateAccount) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock_rounded, size: 15)),
                                Flexible(
                                  child: Text(
                                    c.handle,
                                    overflow: TextOverflow.ellipsis,
                                    style: ts(17, w: FontWeight.w800),
                                  ),
                                ),
                                if (c.verified) ...[const SizedBox(width: 4), const Icon(Icons.verified_rounded, size: 17, color: Color(0xFF3B8BFF))],
                              ],
                            ),
                          ),
                          GlassCircle(Icons.more_horiz_rounded, label: 'More', size: 42, onTap: () => _more(context)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          ProfileAvatar(img: c.img, live: c.live, onTap: c.live ? () => openCreatorLive(context, c) : null),
                          const SizedBox(width: 18),
                          ProfileStat(fmtK(c.posts), 'Posts'),
                          ProfileStat(fmtK(c.followers + (following ? 1 : 0)), 'Followers'),
                          ProfileStat(fmtK(c.following), 'Following'),
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
                              Flexible(child: Text(c.name, style: ds(24))),
                              const SizedBox(width: 8),
                              _pill(categoryByName(c.cat).icon, c.cat, categoryByName(c.cat).tint),
                              if (subbed) ...[const SizedBox(width: 6), _pill(Icons.workspace_premium_rounded, 'Subscribed', const Color(0xFF8E4FA0))],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(c.bio, style: ts(14.5, w: FontWeight.w500, h: 1.4)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded, size: 14, color: UC.muted),
                              const SizedBox(width: 3),
                              Text(
                                c.region,
                                style: ts(13, w: FontWeight.w600, c: UC.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: ProfileButton(
                              following
                                  ? 'Following'
                                  : (c.privateAccount && requested)
                                  ? 'Requested'
                                  : 'Follow',
                              filled: !following && !requested,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (c.privateAccount && !following && !requested) {
                                  setState(() => requested = true);
                                  // demo: the request is accepted a moment later
                                  Future.delayed(const Duration(milliseconds: 1400), () {
                                    if (context.mounted && requested) {
                                      st.toggleFollow(c.id, c.name);
                                      setState(() => requested = false);
                                      toast(context, '${c.name.split(' ').first} accepted your request');
                                    }
                                  });
                                } else if (following) {
                                  st.toggleFollow(c.id, c.name);
                                } else if (!requested) {
                                  st.toggleFollow(c.id, c.name);
                                } else {
                                  setState(() => requested = false);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: ProfileButton(
                              'Message',
                              trailing: !chatOpen(c)
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 6),
                                        const CoinDot(size: 13),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${c.chatPrice}',
                                          style: ts(12.5, w: FontWeight.w800, c: UC.accentText),
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: () => messageCreator(context, c),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Pressable(
                            label: subbed ? 'Subscribed' : 'Subscribe',
                            onTap: () =>
                                subbed ? toast(context, 'You subscribe to ${c.name.split(' ').first}. Manage it in Settings.') : subscribeTo(context, c),
                            child: Container(
                              width: 46,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: subbed ? null : const LinearGradient(colors: [Color(0xFF8E4FA0), UC.primary]),
                                color: subbed ? Colors.white : null,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: const Color(0xFF8E4FA0).withValues(alpha: .25), blurRadius: 14, offset: const Offset(0, 6))],
                              ),
                              child: Icon(Icons.workspace_premium_rounded, color: subbed ? const Color(0xFF8E4FA0) : Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // live timing
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: c.live
                          ? _liveNow(context)
                          : SoftCard(
                              padding: const EdgeInsets.all(14),
                              radius: 24,
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(color: UC.soft, borderRadius: BorderRadius.circular(14)),
                                    child: const Icon(Icons.event_rounded, color: UC.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Goes live ${c.liveDays} · ${c.liveTime}', style: ts(14.5, w: FontWeight.w800)),
                                        const SizedBox(height: 2),
                                        Text(
                                          _accessText(c),
                                          style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Pressable(
                                    label: remind ? 'Reminder on' : 'Remind me',
                                    onTap: () {
                                      setState(() => remind = !remind);
                                      if (remind) toast(context, 'We’ll ping you when ${c.name.split(' ').first} goes live');
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(color: remind ? UC.ink : UC.surface, shape: BoxShape.circle),
                                      child: Icon(
                                        remind ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                        size: 20,
                                        color: remind ? Colors.white : UC.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  // highlights
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 104,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        children: [
                          for (final (i, h) in ['Lives', 'Gifts', 'Fans', 'BTS', 'Tour'].indexed)
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(color: UC.line, width: 1.5),
                                    ),
                                    child: Avatar(img: c.photos.isEmpty ? c.img : c.photos[(i + 1) % c.photos.length], size: 58),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(h, style: ts(12, w: FontWeight.w700)),
                                ],
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
                    icons: const [Icons.grid_on_rounded, Icons.slow_motion_video_rounded, Icons.sensors_rounded, Icons.workspace_premium_rounded],
                    index: tab,
                    onTap: (i) => setState(() => tab = i),
                  ),
                ),
                if (locked)
                  SliverToBoxAdapter(child: _privatePanel())
                else if (tab == 0)
                  photoGrid(c.photos, onTap: (_) {})
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
                      itemCount: reelList.length,
                      itemBuilder: (_, i) => ReelThumb(reelList[i], onTap: () => openReels(context, reelList, i)),
                    ),
                  )
                else if (tab == 2)
                  SliverToBoxAdapter(
                    child: PastLives(name: c.name, img: c.img, access: c.access, fee: c.entryFee),
                  )
                else
                  SliverToBoxAdapter(child: _exclusive(context, subbed)),
                SliverToBoxAdapter(child: SizedBox(height: pad.bottom + 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  String _accessText(Creator c) => switch (c.access) {
    LiveAccess.public => 'Public lives · free to watch',
    LiveAccess.paid => 'Private lives · ${c.entryFee} coins entry',
    LiveAccess.subscribers => 'Subscriber lives · ${c.subPrice} coins / month',
  };

  Widget _pill(IconData icon, String t, Color tint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: tint.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tint),
        const SizedBox(width: 4),
        Text(
          t,
          style: ts(12, w: FontWeight.w800, c: tint),
        ),
      ],
    ),
  );

  Widget _liveNow(BuildContext context) => Pressable(
    onTap: () => openCreatorLive(context, c),
    label: 'Watch live',
    child: Container(
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .3), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          fadeInAsset(c.img),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [UC.primary.withValues(alpha: .95), UC.primary.withValues(alpha: .55), Colors.transparent]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LiveBadge(),
                      const SizedBox(height: 6),
                      Text(
                        c.access == LiveAccess.public ? 'Live now · tap to watch' : '${_accessText(c).split(' · ').first} · live now',
                        style: ts(15, w: FontWeight.w800, c: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: UC.primary, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _privatePanel() => Padding(
    padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
    child: Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: UC.ink, width: 2),
          ),
          child: const Icon(Icons.lock_outline_rounded, size: 34),
        ),
        const SizedBox(height: 14),
        Text('This account is private', style: ds(22)),
        const SizedBox(height: 6),
        Text(
          'Follow ${c.name.split(' ').first} to see their posts, reels and past lives.',
          textAlign: TextAlign.center,
          style: ts(14, w: FontWeight.w500, c: UC.muted, h: 1.4),
        ),
      ],
    ),
  );

  Widget _exclusive(BuildContext context, bool subbed) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
    child: Column(
      children: [
        if (!subbed)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Subscriber-only posts', style: ds(20)),
                  const SizedBox(height: 4),
                  Text(
                    '${c.photos.length} exclusive posts and every private live for ${c.subPrice} coins a month.',
                    textAlign: TextAlign.center,
                    style: ts(13.5, w: FontWeight.w500, c: UC.muted, h: 1.4),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton('Subscribe · ${c.subPrice} coins', icon: Icons.workspace_premium_rounded, height: 48, onTap: () => subscribeTo(context, c)),
                ],
              ),
            ),
          ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final p in c.photos.reversed)
              Stack(
                fit: StackFit.expand,
                children: [
                  fadeInAsset(p),
                  if (!subbed)
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: ColoredBox(
                          color: UC.inkA(.2),
                          child: const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 22)),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    ),
  );

  void _more(BuildContext context) => showUmiSheet(
    context,
    (ctx) => GroupedList(
      children: [
        GroupedRow(
          icon: Icons.link_rounded,
          title: 'Copy profile link',
          tint: UC.deep,
          onTap: () {
            Clipboard.setData(ClipboardData(text: 'https://umigo.app/@${c.handle}'));
            Navigator.pop(ctx);
            toast(context, 'Link copied');
          },
        ),
        GroupedRow(
          icon: Icons.notifications_active_rounded,
          title: 'Live notifications',
          tint: UC.primary,
          onTap: () {
            Navigator.pop(ctx);
            setState(() => remind = true);
            toast(context, 'You’ll get a ping for every live');
          },
        ),
        GroupedRow(
          icon: Icons.block_rounded,
          title: 'Block',
          tint: UC.muted,
          onTap: () {
            Navigator.pop(ctx);
            toast(context, '${c.name.split(' ').first} is blocked');
          },
        ),
        GroupedRow(
          icon: Icons.flag_rounded,
          title: 'Report',
          tint: UC.red,
          onTap: () {
            Navigator.pop(ctx);
            toast(context, 'Thanks. Umi Guard will review this profile.');
          },
        ),
      ],
    ),
  );
}

// ---------------- shared profile parts (also used by my own profile) ----------------

class ProfileAvatar extends StatelessWidget {
  final String img;
  final bool live;
  final VoidCallback? onTap;
  final Widget? badge;
  const ProfileAvatar({super.key, required this.img, this.live = false, this.onTap, this.badge});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 96,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: live ? const SweepGradient(colors: [UC.primary, UC.accent, UC.gold, UC.primary]) : null,
              color: live ? null : Colors.white,
              boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .18), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: Avatar(img: img, size: 88, border: Colors.white, borderW: 3),
          ),
          if (live) const Positioned(bottom: 0, child: LiveBadge(scale: .85)),
          if (!live && badge != null) Positioned(bottom: 0, child: badge!),
        ],
      ),
    ),
  );
}

class ProfileStat extends StatelessWidget {
  final String v, l;
  final VoidCallback? onTap;
  const ProfileStat(this.v, this.l, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(v, style: ds(22)),
          Text(
            l,
            style: ts(12.5, w: FontWeight.w600, c: UC.muted),
          ),
        ],
      ),
    ),
  );
}

class ProfileButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  final Widget? trailing;
  final IconData? icon;
  const ProfileButton(this.label, {super.key, required this.onTap, this.filled = false, this.trailing, this.icon});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: filled ? UC.brandGradient : null,
        color: filled ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (filled ? UC.primary : const Color(0xFF6B4A6E)).withValues(alpha: filled ? .28 : .08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 17, color: filled ? Colors.white : UC.ink), const SizedBox(width: 6)],
          Text(
            label,
            style: ts(14, w: FontWeight.w800, c: filled ? Colors.white : UC.ink),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// Icon tabs that stick under the header, with a sliding underline.
class ProfileTabsHeader extends SliverPersistentHeaderDelegate {
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onTap;
  ProfileTabsHeader({required this.icons, required this.index, required this.onTap});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) => Container(
    margin: const EdgeInsets.only(top: 8),
    color: UC.bg.withValues(alpha: overlaps ? .96 : 0),
    child: LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth / icons.length;
        return Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 1, color: UC.line)),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              left: w * index + w * .25,
              width: w * .5,
              bottom: 0,
              height: 2.5,
              child: Container(
                decoration: BoxDecoration(color: UC.ink, borderRadius: BorderRadius.circular(9)),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < icons.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        },
                        child: SizedBox(height: 44, child: Icon(icons[i], size: 24, color: i == index ? UC.ink : UC.muted.withValues(alpha: .7))),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );

  @override
  bool shouldRebuild(covariant ProfileTabsHeader old) => old.index != index || old.icons != icons;
}

Widget photoGrid(List<String> photos, {required ValueChanged<int> onTap}) => SliverPadding(
  padding: const EdgeInsets.all(2),
  sliver: SliverGrid.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
    itemCount: photos.length,
    itemBuilder: (_, i) => StaggerIn(
      index: i,
      stepMs: 30,
      baseMs: 0,
      dy: 10,
      child: GestureDetector(onTap: () => onTap(i), child: fadeInAsset(photos[i])),
    ),
  ),
);

/// Past lives with timing, duration and audience: the "live timing" record.
class PastLives extends StatelessWidget {
  final String name, img;
  final LiveAccess access;
  final int fee;
  const PastLives({super.key, required this.name, required this.img, this.access = LiveAccess.public, this.fee = 0});
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Yesterday', '9:02 PM', '1h 48m', '12.4K', 'Late night requests'),
      ('Sun, 23 Nov', '8:30 PM', '2h 05m', '18.9K', 'PK battle with Kabir'),
      ('Fri, 21 Nov', '7:00 PM', '58m', '6.2K', 'Golden hour set'),
      ('Wed, 19 Nov', '10:15 PM', '1h 20m', '9.8K', 'Ask me anything'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed)
            StaggerIn(
              index: i,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: softBox(22),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 64,
                        height: 76,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            fadeInAsset(img),
                            ColoredBox(color: UC.inkA(.25)),
                            const Center(child: Icon(Icons.replay_rounded, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.$5, style: ts(14.5, w: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(
                            '${r.$1} · ${r.$2}',
                            style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _meta(Icons.timer_outlined, r.$3),
                              const SizedBox(width: 10),
                              _meta(Icons.visibility_outlined, r.$4),
                              if (i == 1 && access != LiveAccess.public) ...[
                                const SizedBox(width: 10),
                                _meta(
                                  access == LiveAccess.paid ? Icons.lock_rounded : Icons.workspace_premium_rounded,
                                  access == LiveAccess.paid ? '$fee coins' : 'Subs',
                                ),
                              ],
                            ],
                          ),
                        ],
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

  Widget _meta(IconData i, String t) => Row(
    children: [
      Icon(i, size: 14, color: UC.deep),
      const SizedBox(width: 3),
      Text(
        t,
        style: ts(12, w: FontWeight.w700, c: UC.deep),
      ),
    ],
  );
}
