import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:livekit_client/livekit_client.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_widgets.dart';
import 'host_live_screen.dart';

/// Camera preview + title, mode and tag, then a 3-2-1 countdown into the host view.
class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});
  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  LocalVideoTrack? preview;
  String? camError;
  final title = TextEditingController(text: 'Sunday night requests');
  String mode = 'Video', tag = 'Music';
  final tools = <String, bool>{'beauty': true, 'mic': true};
  int? count;
  Timer? _t;
  bool front = true;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  Future<void> _openCamera() async {
    try {
      final t = await LocalVideoTrack.createCameraTrack(const CameraCaptureOptions(cameraPosition: CameraPosition.front));
      if (!mounted) {
        await t.stop();
        return;
      }
      setState(() => preview = t);
    } catch (e) {
      if (mounted) setState(() => camError = 'Camera unavailable. Allow camera access to go live.');
    }
  }

  Future<void> _flip() async {
    front = !front;
    try {
      await preview?.setCameraPosition(front ? CameraPosition.front : CameraPosition.back);
    } catch (_) {}
    setState(() {});
  }

  @override
  void dispose() {
    _t?.cancel();
    preview?.stop();
    super.dispose();
  }

  void start() {
    setState(() => count = 3);
    _t = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (count! <= 1) {
        t.cancel();
        await preview?.stop();
        preview = null;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HostLiveScreen(title: title.text.trim(), tag: tag, pk: mode == 'PK battle'),
          ),
        );
      } else {
        setState(() => count = count! - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: UC.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveVideo(track: preview, fallbackImg: preview == null ? 'assets/img/ava.jpg' : null, mirror: front),
          ),
          const Positioned.fill(child: ShadeOverlay()),
          Positioned(
            top: pad.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                RoundGlassButton(Icons.close_rounded, tooltip: 'Close', size: 38, onTap: () => Navigator.pop(context)),
                const Spacer(),
                for (final t in [
                  ('flip', Icons.flip_camera_ios_rounded, 'Flip'),
                  ('beauty', Icons.auto_awesome_rounded, 'Beauty'),
                  ('filter', Icons.filter_vintage_rounded, 'Filters'),
                  ('mic', Icons.mic_rounded, 'Mic'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      children: [
                        RoundGlassButton(
                          t.$2,
                          tooltip: t.$3,
                          size: 40,
                          gradient: (tools[t.$1] ?? false) ? const LinearGradient(colors: [UC.primary, UC.primary]) : null,
                          onTap: () {
                            if (t.$1 == 'flip') {
                              _flip();
                            } else {
                              setState(() => tools[t.$1] = !(tools[t.$1] ?? false));
                            }
                          },
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.$3,
                          style: ts(10.5, w: FontWeight.w800, c: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (camError != null)
            Positioned(
              top: pad.top + 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: UC.inkA(.6), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  camError!,
                  style: ts(12.5, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ),
          if (count != null)
            Positioned.fill(
              child: ColoredBox(
                color: UC.inkA(.45),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Text(
                          '$count',
                          key: ValueKey(count),
                          style: ts(120, w: FontWeight.w800, c: Colors.white),
                        ),
                      ),
                      Text(
                        'Going live…',
                        style: ts(18, w: FontWeight.w800, c: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          _t?.cancel();
                          setState(() => count = null);
                        },
                        child: Text(
                          'Cancel',
                          style: ts(15, w: FontWeight.w800, c: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (count == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(12, 12, 12, pad.bottom + 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Segmented(items: const ['Video', 'Audio room', 'PK battle'], value: mode, onChanged: (v) => setState(() => mode = v)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Text(
                            'Title',
                            style: ts(12.5, w: FontWeight.w800, c: UC.muted),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: title,
                              style: ts(15, w: FontWeight.w800),
                              maxLength: 40,
                              decoration: const InputDecoration(counterText: ''),
                            ),
                          ),
                          const Icon(Icons.edit_rounded, size: 16, color: UC.deep),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final g in ['Music', 'Chat', 'Gaming', 'Dance', 'Study', 'Cooking'])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChipX('#$g', on: g == tag, onTap: () => setState(() => tag = g)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, size: 18, color: UC.deep),
                        const SizedBox(width: 6),
                        Text(
                          'Who can watch',
                          style: ts(13, w: FontWeight.w700, c: UC.muted),
                        ),
                        const Spacer(),
                        Text(
                          'Everyone',
                          style: ts(13, w: FontWeight.w800, c: UC.deep),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(AppState.I.serverConfigured ? Icons.cloud_done_rounded : Icons.science_rounded, size: 18, color: UC.deep),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppState.I.serverConfigured ? 'Real live on your LiveKit server' : 'Demo mode (no server set). Set one in Me › Live server',
                            style: ts(12.5, w: FontWeight.w700, c: UC.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton('Go Live', icon: Icons.videocam_rounded, onTap: start),
                    const SizedBox(height: 8),
                    Text(
                      'By going live you agree to the Community Guidelines',
                      textAlign: TextAlign.center,
                      style: ts(11.5, w: FontWeight.w600, c: UC.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
