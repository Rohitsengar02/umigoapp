import 'package:material_ui/material_ui.dart';

import '../data/social_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/pay_sheet.dart';
import '../widgets/ui.dart';
import 'creator_profile_screen.dart';

/// The Chat tab: conversations only. Notifications live on their own screen.
class MessagesScreen extends StatefulWidget {
  final bool asTab;
  const MessagesScreen({super.key, this.asTab = true});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final q = TextEditingController();
  String filter = 'All';

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBg(
        child: ListenableBuilder(
          listenable: AppState.I,
          builder: (context, _) {
            final st = AppState.I;
            final s = q.text.trim().toLowerCase();
            bool locked(Convo c) => !chatOpen(c.creator);
            final list = convos.where((c) {
              if (s.isNotEmpty && !c.creator.name.toLowerCase().contains(s) && !c.creator.handle.contains(s)) return false;
              return switch (filter) {
                'Unread' => c.unread > 0,
                'Paid' => c.creator.chatPrice > 0,
                _ => true,
              };
            }).toList();
            final unread = convos.fold<int>(0, (a, c) => a + c.unread);
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: staggerSlivers([
                SliverToBoxAdapter(
                  child: LargeTitle(
                    'Messages',
                    eyebrow: unread > 0 ? '$unread unread' : 'All caught up',
                    back: !widget.asTab,
                    actions: [
                      GlassCircle(
                        Icons.notifications_none_rounded,
                        label: 'Activity',
                        size: 42,
                        dot: true,
                        onTap: () => Navigator.pushNamed(context, '/inbox'),
                      ),
                      const SizedBox(width: 8),
                      GlassCircle(Icons.edit_square, label: 'New message', size: 42, onTap: () => _newMessage(context)),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: SearchPill(controller: q, hint: 'Search chats', onChanged: (_) => setState(() {})),
                  ),
                ),
                // active now
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 108,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      children: [
                        for (final c in creators.where((c) => c.live || c.followers > 80000))
                          Pressable(
                            onTap: () => messageCreator(context, c),
                            label: 'Message ${c.name}',
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: c.live ? const SweepGradient(colors: [UC.primary, UC.accent, UC.gold, UC.primary]) : null,
                                          color: c.live ? null : Colors.white,
                                        ),
                                        child: Avatar(img: c.img, size: 58, border: Colors.white),
                                      ),
                                      Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: UC.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(c.name.split(' ').first, style: ts(12, w: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        for (final f in ['All', 'Unread', 'Paid'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChipX(f, on: f == filter, onTap: () => setState(() => filter = f)),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: softBox(28),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          if (list.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(30),
                              child: Text(
                                'No chats here',
                                style: ts(14.5, w: FontWeight.w700, c: UC.muted),
                              ),
                            ),
                          for (final (i, c) in list.indexed) ...[if (i > 0) const Divider(height: 1, indent: 78), _row(context, c, locked(c))],
                        ],
                      ),
                    ),
                  ),
                ),
                // my own price
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: SoftCard(
                      padding: const EdgeInsets.all(14),
                      radius: 24,
                      onTap: () => editChatPrice(context),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: UC.accentSoft, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.payments_rounded, color: UC.accentText),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your chat price', style: ts(14.5, w: FontWeight.w800)),
                                Text(
                                  st.myChatPrice == 0 ? 'Fans message you for free' : 'Fans pay ${st.myChatPrice} coins to open a chat with you',
                                  style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Change',
                            style: ts(13.5, w: FontWeight.w800, c: UC.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: widget.asTab ? navSpace(context) : pad.bottom + 20)),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Convo cv, bool locked) {
    final c = cv.creator;
    return InkWell(
      onTap: () async {
        await messageCreator(context, c);
        if (mounted) setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Avatar(img: c.img, size: 52),
            const SizedBox(width: 12),
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
                          style: ts(15, w: cv.unread > 0 ? FontWeight.w800 : FontWeight.w700),
                        ),
                      ),
                      if (c.verified) ...[const SizedBox(width: 3), const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF3B8BFF))],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cv.msgs.isEmpty ? (locked ? 'Paid chat · say hi for ${c.chatPrice} coins' : 'Say hi 👋') : cv.last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(13.5, w: cv.unread > 0 ? FontWeight.w700 : FontWeight.w500, c: cv.unread > 0 ? UC.ink : UC.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cv.time,
                  style: ts(11.5, w: FontWeight.w600, c: UC.muted),
                ),
                const SizedBox(height: 4),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: UC.accentSoft, borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 11, color: UC.accentText),
                        const SizedBox(width: 3),
                        Text(
                          '${c.chatPrice}',
                          style: ts(11, w: FontWeight.w800, c: UC.accentText),
                        ),
                      ],
                    ),
                  )
                else if (cv.unread > 0)
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                    child: Text(
                      '${cv.unread}',
                      style: ts(11, w: FontWeight.w800, c: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _newMessage(BuildContext context) => showUmiSheet(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New message', style: ds(22)),
        const SizedBox(height: 10),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final c in creators)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Avatar(img: c.img, size: 44),
                  title: Text(c.name, style: ts(15, w: FontWeight.w800)),
                  subtitle: Text(
                    '@${c.handle}',
                    style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                  ),
                  trailing: c.chatPrice == 0
                      ? Text(
                          'Free',
                          style: ts(12.5, w: FontWeight.w800, c: UC.greenText),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CoinDot(size: 13),
                            const SizedBox(width: 3),
                            Text('${c.chatPrice}', style: ts(13, w: FontWeight.w800)),
                          ],
                        ),
                  onTap: () {
                    Navigator.pop(ctx);
                    messageCreator(context, c);
                  },
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Lets me set what fans pay to open a chat with me.
void editChatPrice(BuildContext context) {
  var v = AppState.I.myChatPrice;
  showUmiSheet(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chat price', style: ds(24)),
          const SizedBox(height: 4),
          Text(
            'What a fan pays once to open a chat with you. Subscribers always chat free.',
            style: ts(13.5, w: FontWeight.w500, c: UC.muted, h: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in [0, 9, 19, 29, 49, 99, 199]) ChoiceChipX(p == 0 ? 'Free' : '$p coins', on: v == p, onTap: () => set(() => v = p)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You keep 50% as diamonds (≈ ₹${(v * .05).toStringAsFixed(1)} per chat).',
            style: ts(12.5, w: FontWeight.w600, c: UC.deep),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Save',
            dark: true,
            onTap: () {
              AppState.I.updateProfile(chatPrice: v);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}
