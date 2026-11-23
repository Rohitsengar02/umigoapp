import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../live/live_session.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_widgets.dart';
import '../widgets/mod_widgets.dart';
import '../widgets/skeleton.dart';
import 'gift_sheet.dart';

/// Watching someone live: video, chat, likes, gifts.
class LiveViewerScreen extends StatefulWidget {
  final LiveSession Function() create;
  final Host? demoHost;
  const LiveViewerScreen._(this.create, this.demoHost);

  factory LiveViewerScreen.demo(Host h) =>
      LiveViewerScreen._(() => LiveSession.viewer(roomName: 'demo_${h.id}', hostName: h.name, demoHost: h, title: h.title), h);

  factory LiveViewerScreen.real({required String room, required String hostName, String title = ''}) =>
      LiveViewerScreen._(() => LiveSession.viewer(roomName: room, hostName: hostName, title: title), null);

  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  late final LiveSession s = widget.create();
  final draft = TextEditingController();

  @override
  void initState() {
    super.initState();
    s.start();
    if (!s.demo) AppState.I.addWatched(s.hostIdentity, s.hostName, s.title);
  }

  bool get following => AppState.I.isFollowing(s.hostIdentity);

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  void send() {
    final why = s.sendChat(draft.text);
    if (why != null) toast(context, why);
    // keep the text if it was stopped so the viewer can fix it
    if (why == null || why.startsWith('Some words')) draft.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final h = widget.demoHost;
    return Scaffold(
      backgroundColor: UC.ink,
      resizeToAvoidBottomInset: true,
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: s.sendLike,
                child: LiveVideo(track: s.remoteVideo, fallbackImg: h?.img, heroTag: h == null ? null : 'live_${h.id}'),
              ),
            ),
            if (s.videoHidden) const Positioned.fill(child: VideoBlockedOverlay()),
            const Positioned.fill(child: ShadeOverlay()),
            // header
            Positioned(
              left: 10,
              right: 10,
              top: pad.top + 10,
              child: Row(
                children: [
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: UC.inkA(.45), borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      children: [
                        Avatar(img: h?.img, name: s.hostName, size: 34, border: UC.primary),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.hostName,
                              style: ts(13, w: FontWeight.w800, c: Colors.white),
                            ),
                            Text(
                              '${fmtK(s.viewers)} watching',
                              style: ts(11, w: FontWeight.w700, c: Colors.white.withValues(alpha: .85)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => AppState.I.toggleFollow(s.hostIdentity, s.hostName)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: following ? Colors.white.withValues(alpha: .2) : UC.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              following ? 'Following' : '+ Follow',
                              style: ts(12.5, w: FontWeight.w800, c: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 70,
                    height: 30,
                    child: Stack(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Positioned(
                            right: i * 20.0,
                            child: Avatar(
                              img: ['assets/img/sana.jpg', 'assets/img/rahul.jpg', 'assets/img/meera.jpg'][i],
                              size: 30,
                              border: [const Color(0xFFE0A27A), const Color(0xFFE4E0EA), UC.gold][i],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoundGlassButton(Icons.close_rounded, tooltip: 'Leave live', size: 34, onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Positioned(
              left: 10,
              top: pad.top + 60,
              child: Row(
                children: [
                  GlassPill(
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 13, color: UC.gold),
                        const SizedBox(width: 5),
                        Text(
                          'Daily #12',
                          style: ts(11.5, w: FontWeight.w800, c: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GlassPill(
                    child: Row(
                      children: [
                        const DiamondIcon(size: 13),
                        const SizedBox(width: 5),
                        Text(
                          fmtK(48200 + s.diamondsEarned),
                          style: ts(11.5, w: FontWeight.w800, c: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GuardPill(on: s.guardActive || s.demo),
                  if (!s.demo) ...[
                    const SizedBox(width: 6),
                    GlassPill(
                      child: Text(
                        'REAL',
                        style: ts(10.5, w: FontWeight.w800, c: UC.gold, ls: .8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (s.connecting)
              const Positioned.fill(child: LiveConnectingSkeleton())
            else if (!s.demo && s.remoteVideo == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    s.error != null
                        ? 'Could not join: ${s.error}'
                        : s.ended
                        ? '${s.hostName} ended the live.'
                        : 'Waiting for ${s.hostName}\'s camera…',
                    textAlign: TextAlign.center,
                    style: ts(15, w: FontWeight.w700, c: Colors.white),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: pad.top + 270,
              child: GiftOverlay(gifts: s.gifts),
            ),
            Positioned(
              right: 14,
              bottom: 80 + pad.bottom,
              child: FloatingHearts(taps: s.likeTaps),
            ),
            Positioned(
              left: 10,
              width: 280,
              bottom: 80 + pad.bottom,
              height: 230,
              child: ChatFeed(
                events: s.events,
                onTap: (e) => showReportSheet(context, s, target: e),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: pad.top + 100,
              child: ModNoticeBanner(notices: s.notices),
            ),
            // bottom bar
            Positioned(
              left: 10,
              right: 10,
              bottom: pad.bottom + 18,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      decoration: BoxDecoration(color: UC.inkA(.5), borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: draft,
                              onSubmitted: (_) => send(),
                              textInputAction: TextInputAction.send,
                              style: ts(13.5, w: FontWeight.w600, c: Colors.white),
                              cursorColor: Colors.white,
                              enabled: !s.chatMuted,
                              decoration: InputDecoration(
                                hintText: s.chatMuted
                                    ? 'You are muted by Umi Guard'
                                    : s.slowModeSec > 0
                                    ? 'Slow mode: 1 message / ${s.slowModeSec}s'
                                    : 'Say something nice…',
                                hintStyle: ts(13.5, w: FontWeight.w600, c: Colors.white.withValues(alpha: .75)),
                              ),
                            ),
                          ),
                          RoundGlassButton(
                            Icons.send_rounded,
                            tooltip: 'Send comment',
                            size: 36,
                            gradient: const LinearGradient(colors: [UC.primary, UC.primary]),
                            onTap: send,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoundGlassButton(Icons.flag_rounded, tooltip: 'Report live', onTap: () => showReportSheet(context, s)),
                  const SizedBox(width: 6),
                  RoundGlassButton(
                    Icons.card_giftcard_rounded,
                    tooltip: 'Send a gift',
                    gradient: const LinearGradient(colors: [UC.accent, UC.primary]),
                    onTap: () => showGiftSheet(context, s),
                  ),
                  const SizedBox(width: 6),
                  RoundGlassButton(Icons.favorite_rounded, tooltip: 'Like', color: UC.primary, onTap: s.sendLike),
                ],
              ),
            ),
            if (s.endReason != null) Positioned.fill(child: LiveEndedCard(text: s.endReason!)),
          ],
        ),
      ),
    );
  }
}
