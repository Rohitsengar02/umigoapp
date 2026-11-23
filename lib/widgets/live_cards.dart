import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart' show fmtK;
import '../live/token_api.dart';
import '../screens/live_viewer_screen.dart';
import '../theme.dart';
import 'common.dart';
import 'motion.dart';

/// Opens a real live as a viewer.
void openLive(BuildContext context, LiveRoomInfo r) =>
    Navigator.push(context, umiRoute((_) => LiveViewerScreen.real(room: r.name, hostName: r.hostName, title: r.title)));

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

/// Grid card from the sketch: LIVE + viewers on top, host at the bottom.
class LiveGridCard extends StatelessWidget {
  final LiveRoomInfo r;
  const LiveGridCard(this.r, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => openLive(context, r),
    child: Container(
      decoration: BoxDecoration(gradient: hostGradient(r.hostId), borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: 40,
            child: Text(r.hostName.isEmpty ? '?' : r.hostName.characters.first.toUpperCase(), style: ds(150, c: Colors.white.withValues(alpha: .14))),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x992E1C30)],
                  stops: [.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            right: 8,
            child: Row(
              children: [
                const LiveBadge(),
                const Spacer(),
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(color: UC.inkA(.45), borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        fmtK(r.viewers),
                        style: ts(11, w: FontWeight.w800, c: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ts(13.5, w: FontWeight.w800, c: Colors.white, h: 1.2),
                    ),
                  ),
                Row(
                  children: [
                    Avatar(name: r.hostName, size: 24, border: Colors.white, borderW: 1.5),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(12, w: FontWeight.w800, c: Colors.white),
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
        ? (Icons.wifi_off_rounded, error!, 'Check that your server is running, then pull to refresh.', 'Server settings', '/server')
        : (Icons.videocam_outlined, emptyText, 'Be the first to go live. Your fans will see you here.', 'Go live', '/golive');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(color: UC.soft, shape: BoxShape.circle),
            child: Icon(icon, color: UC.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ts(16, w: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: ts(13, w: FontWeight.w600, c: UC.muted, h: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(width: 170, child: PrimaryButton(btn, height: 44, onTap: () => Navigator.pushNamed(context, route))),
        ],
      ),
    );
  }
}

/// 2-column grid of live cards as a sliver.
Widget liveGridSliver(List<LiveRoomInfo> list) => SliverGrid.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 220),
  itemCount: list.length,
  itemBuilder: (_, i) => StaggerIn(index: i, stepMs: 50, baseMs: 0, child: LiveGridCard(list[i])),
);
