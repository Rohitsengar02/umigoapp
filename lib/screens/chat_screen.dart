import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../data/social_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gift_icons.dart';
import '../widgets/pay_sheet.dart';
import '../widgets/ui.dart';
import 'creator_profile_screen.dart';

/// One conversation. A paid chat must be unlocked with coins before the first
/// message; subscribers and free creators skip that.
class ChatScreen extends StatefulWidget {
  final Creator creator;
  const ChatScreen({super.key, required this.creator});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Convo convo = convoFor(widget.creator.id);
  final draft = TextEditingController();
  final scroll = ScrollController();
  bool typing = false;
  Timer? _reply;
  final _rnd = Random();

  Creator get c => widget.creator;

  bool get open => chatOpen(c);

  @override
  void initState() {
    super.initState();
    convo.unread = 0;
  }

  @override
  void dispose() {
    _reply?.cancel();
    draft.dispose();
    scroll.dispose();
    super.dispose();
  }

  String get _now {
    final t = TimeOfDay.now();
    return '${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  void _add(ChatMsg m) {
    setState(() => convo.msgs.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    });
    if (m.mine) {
      _reply?.cancel();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => typing = true);
      });
      _reply = Timer(Duration(milliseconds: 2000 + _rnd.nextInt(1200)), () {
        if (!mounted) return;
        setState(() => typing = false);
        _add(ChatMsg(m.giftId != null ? 'omg thank you for the ${giftById(m.giftId!).name}!! 💗' : autoReplies[_rnd.nextInt(autoReplies.length)], false, _now));
      });
    }
  }

  void _send() {
    final t = draft.text.trim();
    if (t.isEmpty || !open) return;
    HapticFeedback.lightImpact();
    draft.clear();
    _add(ChatMsg(t, true, _now));
  }

  Future<void> _unlock() async {
    await showPaySheet(
      context,
      title: 'Chat with ${c.name.split(' ').first}',
      sub: 'Pay once to open this chat, then message freely.',
      price: c.chatPrice,
      icon: Icons.chat_bubble_rounded,
      img: c.img,
      cta: 'Pay & start chatting',
      pay: () => AppState.I.unlock('chat:${c.id}', c.chatPrice),
    );
    if (mounted) setState(() {});
  }

  void _gift() {
    showUmiSheet(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Send a gift', style: ds(22))),
              CoinPill(AppState.I.coins, onTap: () => Navigator.pushNamed(context, '/coins')),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .85,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final g in gifts)
                Pressable(
                  label: 'Send ${g.name}',
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!AppState.I.spend(g.price)) {
                      toast(context, 'Not enough coins for ${g.name}');
                      return;
                    }
                    _add(ChatMsg('sent ${g.name}', true, _now, giftId: g.id));
                  },
                  child: Container(
                    decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GiftIcon(g.id, size: 36),
                        const SizedBox(height: 4),
                        Text(g.name, style: ts(12, w: FontWeight.w800)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CoinDot(size: 11),
                            const SizedBox(width: 3),
                            Text(
                              fmtIn(g.price),
                              style: ts(11.5, w: FontWeight.w700, c: UC.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final st = AppState.I;
    final msgs = convo.msgs.reversed.toList();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuroraBg(
        child: Column(
          children: [
            // header
            Padding(
              padding: EdgeInsets.fromLTRB(12, pad.top + 8, 12, 8),
              child: Row(
                children: [
                  GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openCreator(context, c.id),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Avatar(img: c.img, size: 42),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: UC.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: UC.card, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: ts(15.5, w: FontWeight.w800),
                                      ),
                                    ),
                                    if (c.verified) ...[const SizedBox(width: 3), const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF3B8BFF))],
                                  ],
                                ),
                                Text(
                                  typing ? 'typing…' : (c.live ? 'Live now' : 'Active now'),
                                  style: ts(12.5, w: FontWeight.w700, c: typing || c.live ? UC.primary : UC.greenText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GlassCircle(
                    Icons.videocam_rounded,
                    label: 'Video call',
                    size: 42,
                    onTap: () => toast(context, 'Paid 1:1 video calls arrive with the backend'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                children: [
                  if (typing) const _Typing(),
                  for (final m in msgs) _bubble(m),
                  // intro
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 10),
                    child: Column(
                      children: [
                        Avatar(img: c.img, size: 78),
                        const SizedBox(height: 8),
                        Text(c.name, style: ds(22)),
                        Text(
                          '@${c.handle} · ${fmtK(c.followers)} followers',
                          style: ts(13, w: FontWeight.w600, c: UC.muted),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: UC.card, borderRadius: BorderRadius.circular(99)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                c.chatPrice == 0 ? Icons.lock_open_rounded : (st.isSubscribed(c.id) ? Icons.workspace_premium_rounded : Icons.lock_rounded),
                                size: 14,
                                color: UC.deep,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.chatPrice == 0
                                    ? 'Free chat'
                                    : st.isSubscribed(c.id)
                                    ? 'Free for subscribers'
                                    : open
                                    ? 'Paid chat · unlocked for ${c.chatPrice} coins'
                                    : 'Paid chat · ${c.chatPrice} coins to unlock',
                                style: ts(12.5, w: FontWeight.w700, c: UC.deep),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // composer or unlock card
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: open
                  ? Padding(
                      key: const ValueKey('open'),
                      padding: EdgeInsets.fromLTRB(12, 6, 12, pad.bottom + 10),
                      child: Glass(
                        radius: BorderRadius.circular(99),
                        tint: UC.glassStrong,
                        padding: const EdgeInsets.all(5),
                        child: Row(
                          children: [
                            Pressable(
                              label: 'Send a gift',
                              onTap: _gift,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(gradient: UC.coinGradient, shape: BoxShape.circle),
                                child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: draft,
                                onSubmitted: (_) => _send(),
                                textInputAction: TextInputAction.send,
                                style: ts(15, w: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: 'Message…',
                                  hintStyle: ts(15, w: FontWeight.w600, c: UC.muted),
                                ),
                              ),
                            ),
                            Pressable(
                              label: 'Send',
                              onTap: _send,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 21),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      key: const ValueKey('locked'),
                      padding: EdgeInsets.fromLTRB(12, 6, 12, pad.bottom + 10),
                      child: SoftCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Unlock this chat', style: ts(15.5, w: FontWeight.w800)),
                                      Text(
                                        'One-time ${c.chatPrice} coins · subscribers chat free',
                                        style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton('Pay ${c.chatPrice} coins', height: 48, icon: Icons.lock_open_rounded, onTap: _unlock),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: PrimaryButton(
                                    'Subscribe',
                                    height: 48,
                                    dark: true,
                                    onTap: () async {
                                      await subscribeTo(context, c);
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMsg m) {
    final gift = m.giftId != null;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Align(
        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .74),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: gift ? 10 : 11),
          decoration: BoxDecoration(
            gradient: m.mine ? (gift ? UC.coinGradient : UC.brandGradient) : null,
            color: m.mine ? null : UC.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(m.mine ? 22 : 6),
              bottomRight: Radius.circular(m.mine ? 6 : 22),
            ),
            boxShadow: [BoxShadow(color: (m.mine ? UC.primary : const Color(0xFF6B4A6E)).withValues(alpha: .1), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: gift
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GiftIcon(m.giftId!, size: 34),
                    const SizedBox(width: 8),
                    Text(
                      'Sent ${giftById(m.giftId!).name}',
                      style: ts(15, w: FontWeight.w800, c: Colors.white),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      m.text,
                      style: ts(15, w: FontWeight.w600, c: m.mine ? Colors.white : UC.ink, h: 1.35),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.time,
                      style: ts(10.5, w: FontWeight.w600, c: m.mine ? Colors.white.withValues(alpha: .75) : UC.muted),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Typing extends StatefulWidget {
  const _Typing();
  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: UC.card, borderRadius: BorderRadius.circular(22)),
      child: AnimatedBuilder(
        animation: a,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: UC.muted.withValues(alpha: .35 + .65 * (sin((a.value * 2 * pi) - i * .9) * .5 + .5)),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
