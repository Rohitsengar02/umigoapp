import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart' show Host, fmtK;
import '../data/social_data.dart' show creatorById;
import '../live/token_api.dart';
import '../screens/live_viewer_screen.dart';
import '../theme.dart';
import 'common.dart';
import 'pay_sheet.dart';
import 'skeleton.dart';
import 'motion.dart';
import 'ui.dart';

/// Opens a live as a viewer: a real room, or the creator's demo live.
void openLive(BuildContext context, LiveRoomInfo r) {
  final c = r.demoId == null ? null : creatorById(r.demoId!);
  if (c != null) {
    final h = Host(c.id, r.hostName, c.img, r.title, c.region, fmtK(r.viewers), c.cat);
    Navigator.push(context, umiRoute((_) => LiveViewerScreen.demo(h)));
    return;
  }
  Navigator.push(context, umiRoute((_) => LiveViewerScreen.real(room: r.name, hostName: r.hostName, title: r.title, access: r.access, fee: r.fee)));
}

/// How long a live has been on, short enough for a card chip: "now", "4m", "1h 5m".
String startedAgo(int startedAt) {
  if (startedAt <= 0) return 'now';
  final m = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startedAt)).inMinutes;
  if (m < 1) return 'now';
  if (m < 60) return '${m}m';
  final h = m ~/ 60;
  return m % 60 == 0 ? '${h}h' : '${h}h ${m % 60}m';
}

/// Card background: the live's thumbnail when there is one, else the host's gradient.
Widget _cardBack(LiveRoomInfo r, double initialSize, double top, double right) => r.img != null
    ? Positioned.fill(child: fadeInAsset(r.img!))
    : Positioned.fill(
        child: Stack(
          children: [
            _CardGlow(r.hostId),
            Positioned(
              right: right,
              top: top,
              child: Text(_initial(r.hostName), style: ds(initialSize, c: Colors.white.withValues(alpha: .15))),
            ),
          ],
        ),
      );

/// Stable gradient per host so every real live gets its own colour.
LinearGradient hostGradient(String key) {
  const sets = [
    [UC.primary, UC.accent],
    [UC.deep, UC.primary],
    [Color(0xFF8E4FA0), Color(0xFFFF9F80)],
    [Color(0xFFB8325E), Color(0xFF6B4A6E)],
    [Color(0xFFE5677F), Color(0xFFFFC46B)],
  ];
  final c = sets[key.hashCode.abs() % sets.length];
  return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c);
}

/// Soft blobs of light drawn over a host gradient, so cards without a photo still feel rich.
class _CardGlow extends StatelessWidget {
  final String seed;
  const _CardGlow(this.seed);
  @override
  Widget build(BuildContext context) {
    final h = seed.hashCode.abs();
    return Stack(
      children: [
        Positioned(
          right: -60 + (h % 40).toDouble(),
          top: -50 + (h % 30).toDouble(),
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Colors.white.withValues(alpha: .38), Colors.white.withValues(alpha: 0)]),
            ),
          ),
        ),
        Positioned(
          left: -70,
          bottom: 30 + (h % 50).toDouble(),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [UC.gold.withValues(alpha: .35), UC.gold.withValues(alpha: 0)]),
            ),
          ),
        ),
      ],
    );
  }
}

String _initial(String n) => n.isEmpty ? '?' : n.characters.first.toUpperCase();

class _Viewers extends StatelessWidget {
  final int n;
  const _Viewers(this.n);
  @override
  Widget build(BuildContext context) => PhotoChip(fmtK(n), leading: const Icon(Icons.visibility_rounded, size: 15, color: Colors.white));
}

/// Grid card: LIVE + viewers on top, title and host at the bottom.
class LiveGridCard extends StatelessWidget {
  final LiveRoomInfo r;

  /// Shows when the live started instead of the viewer count (New tab).
  final bool showAge;
  final double radius;
  const LiveGridCard(this.r, {super.key, this.showAge = false, this.radius = 28});
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => openLive(context, r),
    scale: .96,
    label: 'Watch ${r.hostName} live',
    child: Container(
      decoration: BoxDecoration(
        gradient: hostGradient(r.hostId),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: hostGradient(r.hostId).colors.first.withValues(alpha: radius < 20 ? .12 : .25),
            blurRadius: radius < 20 ? 8 : 18,
            offset: Offset(0, radius < 20 ? 3 : 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          _cardBack(r, 160, 40, -24),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xA62E1C30)],
                  stops: [.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            right: 10,
            child: Row(
              children: [
                const LiveBadge(),
                if (r.isPrivate) ...[const SizedBox(width: 4), AccessBadge(subscribers: r.access == 'subscribers', price: r.fee)],
                const Spacer(),
                if (showAge)
                  PhotoChip(startedAgo(r.startedAt), leading: const Icon(Icons.schedule_rounded, size: 14, color: Colors.white))
                else
                  _Viewers(r.viewers),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ts(14.5, w: FontWeight.w800, c: Colors.white, h: 1.2),
                    ),
                  ),
                Row(
                  children: [
                    Avatar(name: r.hostName, img: r.demoId != null ? r.img : null, size: 26, border: Colors.white, borderW: 1.5),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        r.hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(13, w: FontWeight.w700, c: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Friendly empty state used wherever a list of real lives can be empty.
class NoLives extends StatelessWidget {
  final bool serverConfigured;
  final String? error;
  final String emptyText;
  const NoLives({super.key, required this.serverConfigured, this.error, this.emptyText = 'Nobody is live right now.'});
  @override
  Widget build(BuildContext context) {
    final (icon, title, sub, btn, route) = !serverConfigured
        ? (Icons.cloud_off_rounded, 'Connect your live server', 'Add your server address to see real lives.', 'Add server', '/server')
        : error != null
        ? (Icons.wifi_off_rounded, error!, 'The server may be waking up. Pull down to try again.', 'Server settings', '/server')
        : (Icons.videocam_rounded, emptyText, 'Be the first to go live. Your fans will see you here.', 'Go live', '/golive');
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [UC.blush, UC.peach], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(icon, color: UC.primary, size: 32),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: ds(21)),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: ts(14, w: FontWeight.w500, c: UC.muted, h: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 190,
            child: PrimaryButton(btn, height: 48, dark: true, icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pushNamed(context, route)),
          ),
        ],
      ),
    );
  }
}

/// 2-column grid of live cards as a sliver.
Widget liveGridSliver(List<LiveRoomInfo> list, {bool showAge = false, double gap = 12, double radius = 28}) => SliverGrid.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: gap, crossAxisSpacing: gap, mainAxisExtent: 250),
  itemCount: list.length,
  itemBuilder: (_, i) => StaggerIn(
    index: i,
    stepMs: 50,
    baseMs: 0,
    child: LiveGridCard(list[i], showAge: showAge, radius: radius),
  ),
);
