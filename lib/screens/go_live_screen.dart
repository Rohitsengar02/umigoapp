import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:livekit_client/livekit_client.dart';

import '../live/fx.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fx_sheet.dart';
import '../widgets/live_widgets.dart';
import '../widgets/ui.dart';
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
    LiveFx.I.load();
    LiveFx.I.addListener(_onFx);
    _openCamera();
  }

  void _onFx() {
    if (mounted) setState(() {});
  }

  Future<void> _openCamera() async {
    try {
      final t = await LocalVideoTrack.createCameraTrack(const CameraCaptureOptions(cameraPosition: CameraPosition.front));
      if (!mounted) {
        await t.stop();
        return;
      }
      setState(() => preview = t);
      LiveFx.I.attach(t); // pre-live filters on the preview
    } catch (e) {
      if (mounted) setState(() => camError = 'Camera unavailable. Allow camera access to go live.');
    }
  }

  Future<void> _flip() async {
    front = !front;
    try {
      await preview?.setCameraPosition(front ? CameraPosition.front : CameraPosition.back);
      await LiveFx.I.attach(preview);
    } catch (_) {}
    setState(() {});
  }

  @override
  void dispose() {
    LiveFx.I.removeListener(_onFx);
    _t?.cancel();
    preview?.stop();
    super.dispose();
  }

  bool _toolOn(String id) => switch (id) {
    'beauty' => LiveFx.I.settings.beautyOn,
    'filter' => LiveFx.I.settings.look != 'none',
    'ar' => LiveFx.I.settings.sticker != 'none',
    _ => tools[id] ?? false,
  };

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
            child: ListenableBuilder(
              listenable: LiveFx.I,
              builder: (_, _) => LiveFx.I.preview(LiveVideo(track: preview, fallbackImg: preview == null ? 'assets/img/ava.jpg' : null, mirror: front)),
            ),
          ),
          const Positioned.fill(child: ShadeOverlay()),
          Positioned(
            top: pad.top + 10,
            left: 14,
            child: RoundGlassButton(Icons.close_rounded, tooltip: 'Close', size: 44, onTap: () => Navigator.pop(context)),
          ),
          // camera tools as a vertical glass rail, like a camera app
          Positioned(
            top: pad.top + 10,
            right: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Glass(
                tint: const Color(0x33000000),
                shadow: false,
                radius: BorderRadius.circular(99),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Column(
                  children: [
                    for (final t in [
                      ('flip', Icons.flip_camera_ios_rounded, 'Flip'),
                      ('beauty', Icons.auto_awesome_rounded, 'Beauty'),
                      ('filter', Icons.filter_vintage_rounded, 'Looks'),
                      ('ar', Icons.face_retouching_natural, 'AR'),
                      ('mic', Icons.mic_rounded, 'Mic'),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(
                          children: [
                            RoundGlassButton(
                              t.$2,
                              tooltip: t.$3,
                              size: 42,
                              gradient: _toolOn(t.$1) ? UC.brandGradient : null,
                              onTap: () {
                                if (t.$1 == 'flip') {
                                  _flip();
                                } else if (const ['beauty', 'filter', 'ar'].contains(t.$1)) {
                                  showFxSheet(context, tab: const ['beauty', 'filter', 'ar'].indexOf(t.$1));
                                } else {
                                  setState(() => tools[t.$1] = !(tools[t.$1] ?? false));
                                }
                              },
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t.$3,
                              style: ts(11, w: FontWeight.w700, c: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (camError != null)
            Positioned(
              top: pad.top + 64,
              left: 14,
              right: 90,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: UC.inkA(.6), borderRadius: BorderRadius.circular(16)),
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
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              key: ValueKey('ring$count'),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(seconds: 1),
                              builder: (_, v, _) => SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: v,
                                  strokeWidth: 5,
                                  strokeCap: StrokeCap.round,
                                  color: Colors.white,
                                  backgroundColor: Colors.white.withValues(alpha: .18),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              transitionBuilder: (c, a) => FadeTransition(
                                opacity: a,
                                child: ScaleTransition(
                                  scale: Tween(begin: 1.6, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                                  child: c,
                                ),
                              ),
                              child: Text(
                                '$count',
                                key: ValueKey(count),
                                style: ds(110, c: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
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
              left: 10,
              right: 10,
              bottom: pad.bottom + 10,
              child: Glass(
                radius: BorderRadius.circular(34),
                tint: const Color(0xE6FFFFFF),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(color: UC.ink.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SlideSegmented(items: const ['Video', 'Audio room', 'PK battle'], value: mode, onChanged: (v) => setState(() => mode = v)),
                    const SizedBox(height: 12),
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .08), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 18, color: UC.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: title,
                              style: ts(16, w: FontWeight.w700),
                              maxLength: 40,
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'Give your live a title',
                                hintStyle: ts(16, w: FontWeight.w500, c: UC.muted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        children: [
                          for (final g in ['Music', 'Chat', 'Gaming', 'Dance', 'Study', 'Cooking'])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChipX('#$g', on: g == tag, onTap: () => setState(() => tag = g)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _info(Icons.public_rounded, 'Public'),
                        const SizedBox(width: 8),
                        _info(
                          AppState.I.serverConfigured ? Icons.cloud_done_rounded : Icons.science_rounded,
                          AppState.I.serverConfigured ? 'Real live' : 'Demo mode',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton('Go live', icon: Icons.videocam_rounded, onTap: start),
                    const SizedBox(height: 8),
                    Text(
                      'By going live you agree to the Community Guidelines',
                      textAlign: TextAlign.center,
                      style: ts(12, w: FontWeight.w500, c: UC.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Expanded(
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: UC.ink.withValues(alpha: .05), borderRadius: BorderRadius.circular(99)),
      child: Row(
        children: [
          Icon(icon, size: 17, color: UC.deep),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(13, w: FontWeight.w700, c: UC.ink),
            ),
          ),
        ],
      ),
    ),
  );
}
