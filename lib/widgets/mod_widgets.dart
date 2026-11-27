import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../live/live_session.dart';
import '../theme.dart';
import 'live_widgets.dart';

/// "Umi Guard" shield pill shown on every live. Green dot when the server bot is in the room.
class GuardPill extends StatelessWidget {
  final bool on;
  final VoidCallback? onTap;
  const GuardPill({super.key, required this.on, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: GlassPill(
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, size: 13, color: UC.gold),
          const SizedBox(width: 4),
          Text(
            'Umi Guard',
            style: ts(11, w: FontWeight.w800, c: Colors.white),
          ),
          const SizedBox(width: 5),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: on ? UC.green : Colors.white38),
          ),
        ],
      ),
    ),
  );
}

/// Shows moderation notices as a slide-down banner on top of the live.
class ModNoticeBanner extends StatefulWidget {
  final Stream<ModNotice> notices;
  const ModNoticeBanner({super.key, required this.notices});
  @override
  State<ModNoticeBanner> createState() => _ModNoticeBannerState();
}

class _ModNoticeBannerState extends State<ModNoticeBanner> {
  StreamSubscription<ModNotice>? _sub;
  ModNotice? _n;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _sub = widget.notices.listen(show);
  }

  void show(ModNotice n) {
    _hide?.cancel();
    setState(() => _n = n);
    _hide = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _n = null);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = _n;
    return IgnorePointer(
      child: AnimatedSlide(
        offset: n == null ? const Offset(0, -1.6) : Offset.zero,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: n == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: (n?.bad ?? true) ? const Color(0xF22E1C30) : const Color(0xF2067647),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (n?.bad ?? true) ? UC.primary : UC.green, width: 1.4),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                Icon((n?.bad ?? true) ? Icons.shield_rounded : Icons.check_circle_rounded, size: 20, color: UC.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    n?.text ?? '',
                    style: ts(13, w: FontWeight.w700, c: Colors.white, h: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Blurs the stream when Umi Guard detects nudity on camera.
class VideoBlockedOverlay extends StatelessWidget {
  final bool host;
  const VideoBlockedOverlay({super.key, this.host = false});
  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        color: const Color(0xB32E1C30),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x33FFC46B)),
              child: const Icon(Icons.shield_rounded, size: 40, color: UC.gold),
            ),
            const SizedBox(height: 16),
            Text(
              host ? 'Your camera is paused' : 'Video hidden by Umi Guard',
              textAlign: TextAlign.center,
              style: ts(19, w: FontWeight.w800, c: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              host
                  ? 'Umi Guard spotted content that breaks the rules. Your camera turns back on in a few seconds. 3 strikes ends your live.'
                  : 'This stream may show content that breaks our rules. It will come back when it is clean.',
              textAlign: TextAlign.center,
              style: ts(13.5, w: FontWeight.w600, c: Colors.white.withValues(alpha: .85), h: 1.45),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Full-screen card when a viewer is removed or the live is ended by Umi Guard.
class LiveEndedCard extends StatelessWidget {
  final String text;
  const LiveEndedCard({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    color: UC.night,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shield_rounded, size: 46, color: UC.gold),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: ts(17, w: FontWeight.w800, c: Colors.white, h: 1.35),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: UC.primary, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
          child: Text(
            'Back to Home',
            style: ts(14, w: FontWeight.w800, c: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _sheet(BuildContext context, String title, List<Widget> children) => SafeArea(
  child: Padding(
    padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: UC.line, borderRadius: BorderRadius.circular(9)),
          ),
        ),
        const SizedBox(height: 14),
        Text(title, style: ds(23)),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  ),
);

Widget _option(IconData icon, String label, String sub, VoidCallback onTap, {Color color = UC.deep}) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)),
    child: Icon(icon, color: color, size: 21),
  ),
  title: Text(
    label,
    style: ts(14.5, w: FontWeight.w800, c: color),
  ),
  subtitle: Text(
    sub,
    style: ts(12, w: FontWeight.w600, c: UC.muted),
  ),
  onTap: onTap,
);

const reportReasons = ['Nudity or sexual content', 'Hate or harassment', 'Scam or fraud', 'Violence or danger', 'Underage user', 'Spam'];

/// Report the host (target == null) or a chat message.
Future<void> showReportSheet(BuildContext context, LiveSession s, {LiveEvent? target}) => showModalBottomSheet(
  context: context,
  backgroundColor: UC.card,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
  builder: (c) => _sheet(c, target == null ? 'Report this live' : 'Report ${target.name}', [
    if (target != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '"${target.text}"',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ts(13, w: FontWeight.w600, c: UC.muted),
        ),
      ),
    for (final r in reportReasons)
      ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(r, style: ts(14.5, w: FontWeight.w700)),
        trailing: Icon(Icons.chevron_right_rounded, color: UC.muted),
        onTap: () {
          s.report(r, who: target?.senderId ?? '');
          Navigator.pop(c);
        },
      ),
  ]),
);

/// Host taps a viewer's chat line: mute / remove / ban.
Future<void> showViewerActions(BuildContext context, LiveSession s, LiveEvent e) => showModalBottomSheet(
  context: context,
  backgroundColor: UC.card,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
  builder: (c) {
    void act(String cmd, {int sec = 600}) {
      s.hostAction(cmd, e, sec: sec);
      Navigator.pop(c);
    }

    return _sheet(c, e.name, [
      Text(
        '"${e.text}"',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: ts(13, w: FontWeight.w600, c: UC.muted),
      ),
      const SizedBox(height: 6),
      _option(Icons.volume_off_rounded, 'Mute 10 min', 'They can watch but not chat', () => act('mute')),
      _option(Icons.volume_up_rounded, 'Unmute', 'Let them chat again', () => act('unmute', sec: 0)),
      _option(Icons.logout_rounded, 'Remove from live', 'Kicked out, can come back in 1 hour', () => act('kick', sec: 3600), color: UC.accentText),
      _option(Icons.block_rounded, 'Ban for 7 days', 'Cannot join any of your lives', () => act('ban', sec: 7 * 86400), color: UC.red),
    ]);
  },
);

/// Host moderation panel: slow mode, blocked words, recent actions.
Future<void> showModPanel(BuildContext context, LiveSession s) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: UC.card,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
  builder: (c) => _ModPanel(s: s),
);

class _ModPanel extends StatefulWidget {
  final LiveSession s;
  const _ModPanel({required this.s});
  @override
  State<_ModPanel> createState() => _ModPanelState();
}

class _ModPanelState extends State<_ModPanel> {
  late final words = TextEditingController(text: widget.s.customWords.join(', '));

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        child: SingleChildScrollView(
          child: _sheet(context, 'Umi Guard', [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: s.guardActive || s.demo ? UC.green : UC.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.guardOn
                        ? 'Watching chat and video in real time (server)'
                        : 'Running inside the app: every phone checks chat, your phone checks your camera',
                    style: ts(13, w: FontWeight.w700, c: UC.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [_tile('${s.removedCount}', 'messages stopped'), const SizedBox(width: 10), _tile('${s.modLog.length}', 'actions')]),
            const SizedBox(height: 18),
            Text('Slow mode', style: ts(14.5, w: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final sec in [0, 3, 10, 30])
                  ChoiceChip(
                    label: Text(sec == 0 ? 'Off' : '${sec}s'),
                    selected: s.slowModeSec == sec,
                    selectedColor: UC.soft,
                    labelStyle: ts(13, w: FontWeight.w800, c: s.slowModeSec == sec ? UC.primary : UC.ink),
                    onSelected: (_) => s.setSlowMode(sec),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Extra blocked words', style: ts(14.5, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Comma separated. Messages with these words are hidden.',
              style: ts(12, w: FontWeight.w600, c: UC.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: words,
              style: ts(14, w: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. spoiler, rival_name',
                filled: true,
                fillColor: UC.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  tooltip: 'Save words',
                  icon: const Icon(Icons.check_rounded, color: UC.primary),
                  onPressed: () {
                    s.setCustomWords(words.text.split(','));
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Recent actions', style: ts(14.5, w: FontWeight.w800)),
            const SizedBox(height: 6),
            if (s.modLog.isEmpty)
              Text(
                'Nothing yet. Tap any chat message to mute or remove that viewer.',
                style: ts(13, w: FontWeight.w600, c: UC.muted),
              )
            else
              for (final l in s.modLog.take(12))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 15, color: UC.deep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l, style: ts(13, w: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
          ]),
        ),
      ),
    );
  }

  Widget _tile(String v, String l) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v,
            style: ts(20, w: FontWeight.w800, c: UC.primary),
          ),
          Text(
            l,
            style: ts(12, w: FontWeight.w700, c: UC.muted),
          ),
        ],
      ),
    ),
  );
}
