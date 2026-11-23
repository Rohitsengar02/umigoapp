import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/common.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String tab = 'Activity';
  bool read = false;
  bool pkAnswered = false;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final acts = [
      ('PK', 'Kabir_v challenged you to a PK', '5-minute battle, winner gets 2× gift points tonight.', '2m', true, 'assets/img/kabir2.jpg'),
      ('GIFT', 'Rahul_K sent you Rocket ×3', '+1,498 diamonds added to your earnings.', '18m', true, 'assets/img/rahul.jpg'),
      ('FAN', '184 new fans from your live', 'Meera, Sana and 182 others followed you.', '1h', true, 'assets/img/meera.jpg'),
      ('₹', 'Withdrawal processing', '₹2,000 to HDFC ••• 2210. Arrives within 24 hours.', '1d', false, ''),
      ('LV', 'You reached Level 12', 'New badge unlocked. 660 XP to Level 13.', '2d', false, ''),
    ];
    final msgs = [
      ('Priya.r', 'assets/img/priya.jpg', 'Thank you for the Rocket!! 💗', '9:12 PM', 2, true),
      ('Kabir_v', 'assets/img/kabir.jpg', 'PK tomorrow at 9?', '8:40 PM', 1, true),
      ('Zara S', 'assets/img/zara.jpg', 'haha yes that song', 'Yesterday', 0, false),
      ('Meera', 'assets/img/meera.jpg', 'See you in my live 🎶', 'Yesterday', 0, false),
      ('Umigo Team', '', 'Welcome to Umigo! Here are 3 tips…', 'Mon', 0, false),
    ];
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: pad.top),
          TopBar(
            'Inbox',
            actions: [
              TextButton(
                onPressed: () => setState(() => read = true),
                child: Text(
                  'Mark all read',
                  style: ts(13, w: FontWeight.w800, c: UC.deep),
                ),
              ),
            ],
          ),
          Segmented(items: const ['Activity', 'Messages'], value: tab, onChanged: (v) => setState(() => tab = v)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(12, 4, 12, pad.bottom + 12),
              children: [
                if (tab == 'Activity')
                  for (final a in acts)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: a.$5 && !read ? UC.soft : UC.surface, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          a.$6.isNotEmpty
                              ? Avatar(img: a.$6, size: 44)
                              : Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: UC.accentSoft, borderRadius: BorderRadius.circular(14)),
                                  child: Text(
                                    a.$1,
                                    style: ts(12, w: FontWeight.w800, c: UC.accentText),
                                  ),
                                ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.$2, style: ts(14, w: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  a.$3,
                                  style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                ),
                                if (a.$1 == 'PK' && !pkAnswered) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      FilledButton(
                                        onPressed: () {
                                          setState(() => pkAnswered = true);
                                          Navigator.pushNamed(context, '/golive');
                                        },
                                        style: FilledButton.styleFrom(backgroundColor: UC.primary, minimumSize: const Size(0, 34)),
                                        child: Text(
                                          'Accept PK',
                                          style: ts(12.5, w: FontWeight.w800, c: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        onPressed: () => setState(() => pkAnswered = true),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 34),
                                          side: const BorderSide(color: UC.line),
                                        ),
                                        child: Text(
                                          'Later',
                                          style: ts(12.5, w: FontWeight.w800, c: UC.ink),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            a.$4,
                            style: ts(11.5, w: FontWeight.w700, c: UC.muted),
                          ),
                        ],
                      ),
                    )
                else
                  for (final m in msgs)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Avatar(img: m.$2, name: m.$1, size: 48),
                          if (m.$6)
                            Positioned(
                              bottom: -3,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: UC.primary,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  'LIVE',
                                  style: ts(8, w: FontWeight.w800, c: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(m.$1, style: ts(14.5, w: FontWeight.w800)),
                      subtitle: Text(
                        m.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            m.$4,
                            style: ts(11, w: FontWeight.w700, c: UC.muted),
                          ),
                          const SizedBox(height: 4),
                          if (m.$5 > 0 && !read)
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: UC.primary, shape: BoxShape.circle),
                              child: Text(
                                '${m.$5}',
                                style: ts(11, w: FontWeight.w800, c: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
