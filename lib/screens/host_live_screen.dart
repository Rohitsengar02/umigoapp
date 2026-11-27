import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../live/fx.dart';
import '../live/live_session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fx_sheet.dart';
import '../widgets/live_widgets.dart';
import '../widgets/ui.dart';
import '../widgets/mod_widgets.dart';

/// The host's own live: camera, viewers, incoming chat and gifts, PK bar, earnings.
class HostLiveScreen extends StatefulWidget {
  final String title, tag;
  final bool pk;
  const HostLiveScreen({super.key, required this.title, required this.tag, this.pk = false});
  @override
  State<HostLiveScreen> createState() => _HostLiveScreenState();
}

class _HostLiveScreenState extends State<HostLiveScreen> {
  late final LiveSession s = LiveSession.host(title: widget.title, tag: widget.tag);
  Timer? _tick;
  final draft = TextEditingController();
  int theirs = 12920;
  int pkLeft = 300;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    s.start();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (widget.pk && pkLeft > 0) {
          pkLeft--;
          if (_rnd.nextDouble() < .3) theirs += [1, 5, 10, 49, 299][_rnd.nextInt(5)];
        }
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    s.dispose();
    super.dispose();
  }

  void _say() {
    final why = s.sendChat(draft.text);
    if (why != null) toast(context, why);
    if (why == null || why.startsWith('Some words')) draft.clear();
  }

  String _clock(Duration d) =>
      '${d.inHours > 0 ? '${d.inHours}:' : ''}${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _end() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('End your live?', style: ts(19, w: FontWeight.w800)),
        content: Text(
          'You earned ${fmtIn(s.diamondsEarned)} diamonds from ${s.giftersCount} gifters in ${_clock(s.elapsed)}.',
          style: ts(14, w: FontWeight.w600, c: UC.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(
              'Keep going',
              style: ts(14, w: FontWeight.w800, c: UC.deep),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: UC.primary),
            child: Text(
              'End live',
              style: ts(14, w: FontWeight.w800, c: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (!did) _end();
      },
      child: Scaffold(
        backgroundColor: UC.ink,
        body: ListenableBuilder(
          listenable: Listenable.merge([s, LiveFx.I]),
          builder: (context, _) {
            final mine = 18640 + s.diamondsEarned * 2;
            final pct = mine / (mine + theirs);
            return Stack(
              children: [
                Positioned.fill(
                  child: LiveFx.I.preview(LiveVideo(track: s.localVideo, fallbackImg: 'assets/img/ava.jpg', mirror: s.camFront)),
                ),
                const Positioned.fill(child: ShadeOverlay()),
                if (s.videoBlocked) const Positioned.fill(child: VideoBlockedOverlay(host: true)),
                Positioned(
                  top: pad.top + 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      const LiveBadge(scale: 1.2),
                      const SizedBox(width: 6),
                      GlassPill(
                        child: Text(
                          _clock(s.elapsed),
                          style: ts(12, w: FontWeight.w800, c: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GlassPill(
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              fmtIn(s.viewers),
                              style: ts(12, w: FontWeight.w800, c: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GuardPill(on: s.guardActive || s.demo, onTap: () => showModPanel(context, s)),
                      const Spacer(),
                      Pressable(
                        onTap: _end,
                        label: 'End live',
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [BoxShadow(color: UC.inkA(.25), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Text(
                            'End',
                            style: ts(14, w: FontWeight.w800, c: UC.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: pad.top + 54,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.isEmpty ? 'My live' : widget.title,
                        style: ts(15, w: FontWeight.w800, c: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.demo
                            ? 'Demo mode · simulated viewers'
                            : s.error != null
                            ? 'Server error: ${s.error}'
                            : s.connecting
                            ? 'Connecting to your LiveKit server…'
                            : 'Real live · room ${s.roomName}',
                        maxLines: 2,
                        style: ts(11.5, w: FontWeight.w700, c: s.error != null ? UC.gold : Colors.white.withValues(alpha: .8)),
                      ),
                      if (widget.pk) ...[const SizedBox(height: 10), _pkBar(mine, pct)],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _stat('Diamonds', fmtIn(s.diamondsEarned), const DiamondIcon(size: 14)),
                          const SizedBox(width: 6),
                          _stat('Gifters', '${s.giftersCount}', const Icon(Icons.card_giftcard_rounded, size: 14, color: UC.accent)),
                          const SizedBox(width: 6),
                          _stat('Likes', fmtK(s.likes), const Icon(Icons.favorite_rounded, size: 14, color: UC.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: pad.top + (widget.pk ? 270 : 220),
                  child: GiftOverlay(gifts: s.gifts),
                ),
                Positioned(
                  right: 70,
                  bottom: 80 + pad.bottom,
                  child: FloatingHearts(taps: s.likeTaps),
                ),
                // host controls as a vertical glass rail on the right
                Positioned(
                  right: 10,
                  bottom: pad.bottom + 80,
                  child: GlassPill(
                    height: 5 * 54 + 12,
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    expand: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RoundGlassButton(s.micOn ? Icons.mic_rounded : Icons.mic_off_rounded, tooltip: 'Mic', size: 46, onTap: s.toggleMic),
                        RoundGlassButton(Icons.flip_camera_ios_rounded, tooltip: 'Flip camera', size: 46, onTap: s.flipCamera),
                        RoundGlassButton(
                          Icons.auto_awesome_rounded,
                          tooltip: 'Filters',
                          size: 46,
                          gradient: LiveFx.I.settings.any ? UC.brandGradient : null,
                          onTap: () => showFxSheet(context),
                        ),
                        RoundGlassButton(Icons.shield_rounded, tooltip: 'Moderation', size: 46, color: UC.gold, onTap: () => showModPanel(context, s)),
                        RoundGlassButton(
                          Icons.account_balance_wallet_rounded,
                          tooltip: 'Earnings',
                          size: 46,
                          onTap: () => toast(context, 'This live: ${fmtIn(s.diamondsEarned)} diamonds ≈ ₹${fmtIn(s.diamondsEarned ~/ 10)}'),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  width: 280,
                  bottom: 80 + pad.bottom,
                  height: 240,
                  child: ChatFeed(events: s.events, onTap: (e) => showViewerActions(context, s, e)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: pad.top + 100,
                  child: ModNoticeBanner(notices: s.notices),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: pad.bottom + 18,
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassPill(
                          expand: true,
                          height: 50,
                          padding: const EdgeInsets.only(left: 18, right: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: draft,
                                  onSubmitted: (_) => _say(),
                                  style: ts(15, w: FontWeight.w600, c: Colors.white),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    hintText: 'Talk to your viewers…',
                                    hintStyle: ts(15, w: FontWeight.w500, c: Colors.white.withValues(alpha: .75)),
                                  ),
                                ),
                              ),
                              RoundGlassButton(Icons.send_rounded, tooltip: 'Send', size: 40, gradient: UC.brandGradient, onTap: _say),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.endReason != null) Positioned.fill(child: LiveEndedCard(text: s.endReason!)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String v, Widget icon) => GlassPill(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v,
              style: ts(13, w: FontWeight.w800, c: Colors.white),
            ),
            Text(
              label,
              style: ts(9.5, w: FontWeight.w700, c: Colors.white.withValues(alpha: .75)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _pkBar(int mine, double pct) => Column(
    children: [
      Row(
        children: [
          Avatar(img: 'assets/img/ava.jpg', size: 26, border: UC.primary),
          const SizedBox(width: 6),
          Text(
            'You',
            style: ts(12, w: FontWeight.w800, c: Colors.white),
          ),
          const Spacer(),
          GlassPill(
            child: Text(
              'PK ${_clock(Duration(seconds: pkLeft))}',
              style: ts(11.5, w: FontWeight.w800, c: UC.gold),
            ),
          ),
          const Spacer(),
          Text(
            'Kabir_v',
            style: ts(12, w: FontWeight.w800, c: Colors.white),
          ),
          const SizedBox(width: 6),
          Avatar(img: 'assets/img/kabir.jpg', size: 26, border: UC.deep),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 22,
          child: Row(
            children: [
              Expanded(
                flex: (pct * 1000).round(),
                child: Container(
                  color: UC.primary,
                  padding: const EdgeInsets.only(left: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmtIn(mine),
                    style: ts(11.5, w: FontWeight.w800, c: Colors.white),
                  ),
                ),
              ),
              Expanded(
                flex: ((1 - pct) * 1000).round(),
                child: Container(
                  color: UC.deep,
                  padding: const EdgeInsets.only(right: 8),
                  alignment: Alignment.centerRight,
                  child: Text(
                    fmtIn(theirs),
                    style: ts(11.5, w: FontWeight.w800, c: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
