import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:livekit_client/livekit_client.dart';

import '../data/demo_data.dart' show fmtK;
import '../data/social_data.dart' show LiveAccess, accessColor;
import '../live/fx.dart';
import '../live/live_setup.dart';
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
  final setup = LiveSetup(title: 'Sunday night requests');
  final tipLabel = TextEditingController();
  final goalLabel = TextEditingController(text: 'New mic fund');
  int tipCoins = 50;
  int step = 0;
  bool back = false; // slide direction between steps
  String get mode => setup.mode;
  String get tag => setup.tag;
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
    title.dispose();
    tipLabel.dispose();
    goalLabel.dispose();
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
            builder: (_) => HostLiveScreen(
              title: title.text.trim(),
              tag: tag,
              pk: mode == 'PK battle',
              setup: setup
                ..title = title.text.trim()
                ..goalLabel = goalLabel.text.trim().isEmpty ? 'Tonight’s goal' : goalLabel.text.trim(),
            ),
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
            // camera tools while setting the basics; out of the way for the taller steps
            child: IgnorePointer(
              ignoring: step != 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: step == 0 ? 1 : 0,
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
          if (count == null) Positioned(left: 10, right: 10, bottom: pad.bottom + 10, child: _panel(context)),
        ],
      ),
    );
  }

  static const _steps = ['Basics', 'Audience', 'Earn', 'Review'];

  void _go(int to) {
    FocusScope.of(context).unfocus();
    setState(() {
      back = to < step;
      step = to;
    });
  }

  Widget _panel(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .56;
    return Glass(
      radius: BorderRadius.circular(34),
      tint: const Color(0xEBFFFFFF),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
          // step header: label + segmented progress
          Row(
            children: [
              Text(
                'Step ${step + 1} of 4',
                style: ts(12.5, w: FontWeight.w800, c: UC.primary),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${_steps[step]}',
                style: ts(12.5, w: FontWeight.w800, c: UC.muted),
              ),
              const Spacer(),
              for (var i = 0; i < 4; i++)
                GestureDetector(
                  onTap: i < step ? () => _go(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(left: 4),
                    width: i == step ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: i <= step ? UC.brandGradient : null,
                      color: i <= step ? null : UC.ink.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) {
                final incoming = c.key == ValueKey(step);
                final dx = (incoming ? 1 : -1) * (back ? -1 : 1) * .12;
                return FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                    child: c,
                  ),
                );
              },
              layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, ?cur]),
              child: ConstrainedBox(
                key: ValueKey(step),
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: switch (step) {
                    0 => _basics(),
                    1 => _audience(),
                    2 => _earn(),
                    _ => _review(),
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (step > 0) ...[
                Pressable(
                  label: 'Back',
                  onTap: () => _go(step - 1),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: UC.ink.withValues(alpha: .06), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_rounded, color: UC.ink),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: step < 3
                    ? PrimaryButton('Next · ${_steps[step + 1]}', dark: true, icon: Icons.arrow_forward_rounded, onTap: () => _go(step + 1))
                    : PrimaryButton(
                        setup.isPrivate ? 'Go live privately' : 'Go live',
                        icon: setup.isPrivate ? Icons.lock_rounded : Icons.videocam_rounded,
                        onTap: start,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String t, [String? sub]) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Row(
      children: [
        Text(t, style: ts(13.5, w: FontWeight.w800)),
        if (sub != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              sub,
              overflow: TextOverflow.ellipsis,
              style: ts(12, w: FontWeight.w600, c: UC.muted),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _field(TextEditingController c, String hint, IconData icon, {int max = 40, TextInputType? type}) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .08), blurRadius: 14, offset: const Offset(0, 5))],
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: UC.primary),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: c,
            style: ts(15.5, w: FontWeight.w700),
            maxLength: max,
            keyboardType: type,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: ts(15, w: FontWeight.w500, c: UC.muted),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chips<T>(List<T> items, T value, String Function(T) label, ValueChanged<T> on) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChipX(label(i), on: i == value, onTap: () => setState(() => on(i))),
          ),
      ],
    ),
  );

  Widget _toggle(IconData icon, String title, String sub, bool v, ValueChanged<bool> on) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: UC.soft, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18, color: UC.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ts(14, w: FontWeight.w800)),
              Text(
                sub,
                style: ts(12, w: FontWeight.w500, c: UC.muted),
              ),
            ],
          ),
        ),
        Switch.adaptive(value: v, activeTrackColor: UC.primary, onChanged: (x) => setState(() => on(x))),
      ],
    ),
  );

  // ---- step 1: mode, title, tag
  Widget _basics() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SlideSegmented(items: const ['Video', 'Audio room', 'PK battle'], value: mode, onChanged: (v) => setState(() => setup.mode = v)),
      const SizedBox(height: 12),
      _field(title, 'Give your live a title', Icons.edit_rounded),
      const SizedBox(height: 12),
      _label('Category'),
      _chips(['Music', 'Talk', 'Gaming', 'Dance', 'Comedy', 'Study', 'Fitness', 'Cooking'], tag, (g) => '#$g', (g) => setup.tag = g),
      const SizedBox(height: 10),
      Row(
        children: [
          _info(Icons.place_rounded, 'All India'),
          const SizedBox(width: 8),
          _info(AppState.I.serverConfigured ? Icons.cloud_done_rounded : Icons.science_rounded, AppState.I.serverConfigured ? 'Real live' : 'Demo mode'),
        ],
      ),
    ],
  );

  // ---- step 2: who can watch
  Widget _audience() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final a in [
        (LiveAccess.public, Icons.public_rounded, 'Public', 'Anyone can join for free'),
        (LiveAccess.paid, Icons.lock_rounded, 'Private · paid entry', 'Viewers pay coins once to join'),
        (LiveAccess.subscribers, Icons.workspace_premium_rounded, 'Private · subscribers', 'Only your monthly subscribers'),
      ])
        Pressable(
          label: a.$3,
          onTap: () => setState(() => setup.access = a.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: setup.access == a.$1 ? UC.primary : Colors.white, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: (setup.access == a.$1 ? UC.primary : const Color(0xFF6B4A6E)).withValues(alpha: .1),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: accessColor(a.$1).withValues(alpha: .14), shape: BoxShape.circle),
                  child: Icon(a.$2, color: accessColor(a.$1), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.$3, style: ts(14.5, w: FontWeight.w800)),
                      Text(
                        a.$4,
                        style: ts(12.5, w: FontWeight.w500, c: UC.muted),
                      ),
                    ],
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  scale: setup.access == a.$1 ? 1 : 0,
                  child: const Icon(Icons.check_circle_rounded, color: UC.primary),
                ),
              ],
            ),
          ),
        ),
      if (setup.access == LiveAccess.paid) ...[
        _label('Entry fee', 'you keep 50% as diamonds'),
        _chips([19, 49, 99, 199, 499], setup.entryFee, (v) => '$v coins', (v) => setup.entryFee = v),
      ],
      if (setup.access == LiveAccess.subscribers) ...[
        _label('Subscription', 'per month, also unlocks chat'),
        _chips([99, 149, 199, 299, 499], setup.subPrice, (v) => '$v / mo', (v) => setup.subPrice = v),
      ],
      const SizedBox(height: 8),
      _toggle(Icons.forum_rounded, 'Followers-only chat', 'New viewers watch, followers talk', setup.followersChat, (v) => setup.followersChat = v),
    ],
  );

  // ---- step 3: tip menu + gift goal
  Widget _earn() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _toggle(Icons.local_activity_rounded, 'Tip menu', 'Viewers pay coins for an action', setup.tipsOn, (v) => setup.tipsOn = v),
      if (setup.tipsOn) ...[
        for (final (i, t) in setup.tips.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
            decoration: BoxDecoration(color: UC.accentSoft, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Text(t.label, style: ts(14, w: FontWeight.w700)),
                ),
                const CoinDot(size: 15),
                const SizedBox(width: 4),
                Text('${t.coins}', style: ts(14, w: FontWeight.w800)),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => setup.tips.removeAt(i)),
                  icon: const Icon(Icons.close_rounded, size: 18, color: UC.muted),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _field(tipLabel, 'Add an action…', Icons.add_rounded, max: 28)),
            const SizedBox(width: 8),
            Pressable(
              label: 'Add tip',
              onTap: () {
                final l = tipLabel.text.trim();
                if (l.isEmpty) return;
                setState(() => setup.tips.add(TipItem(l, tipCoins)));
                tipLabel.clear();
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: UC.ink, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    const CoinDot(size: 15),
                    const SizedBox(width: 5),
                    Text(
                      '$tipCoins',
                      style: ts(14, w: FontWeight.w800, c: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _chips([10, 20, 50, 100, 300, 500], tipCoins, (v) => '$v', (v) => tipCoins = v),
        const SizedBox(height: 10),
      ],
      _toggle(Icons.flag_rounded, 'Gift goal', 'A bar fills as gifts and tips come in', setup.goalOn, (v) => setup.goalOn = v),
      if (setup.goalOn) ...[
        _field(goalLabel, 'What is the goal for?', Icons.flag_rounded, max: 30),
        const SizedBox(height: 8),
        _chips([1000, 2500, 5000, 10000, 25000], setup.goalCoins, (v) => '${fmtK(v)} coins', (v) => setup.goalCoins = v),
      ],
    ],
  );

  // ---- step 4: extras + summary
  Widget _review() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [UC.soft, UC.accentSoft.withValues(alpha: .8)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.text.trim().isEmpty ? 'My live' : title.text.trim(), style: ds(20)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _sum(Icons.videocam_rounded, mode),
                _sum(Icons.tag_rounded, tag),
                _sum(setup.access == LiveAccess.public ? Icons.public_rounded : Icons.lock_rounded, switch (setup.access) {
                  LiveAccess.public => 'Public',
                  LiveAccess.paid => '${setup.entryFee} coins entry',
                  LiveAccess.subscribers => 'Subscribers · ${setup.subPrice}/mo',
                }),
                if (setup.tipsOn) _sum(Icons.local_activity_rounded, '${setup.tips.length} tips'),
                if (setup.goalOn) _sum(Icons.flag_rounded, '${fmtK(setup.goalCoins)} goal'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _toggle(Icons.group_add_rounded, 'Co-host requests', 'Let viewers ask to join on screen', setup.coHost, (v) => setup.coHost = v),
      _toggle(Icons.video_library_rounded, 'Save replay', 'Shows on your profile under Lives', setup.saveReplay, (v) => setup.saveReplay = v),
      _toggle(Icons.emoji_events_rounded, 'Top gifters board', 'Show the top 3 gifters on screen', setup.showTopGifters, (v) => setup.showTopGifters = v),
      Text(
        'By going live you agree to the Community Guidelines. Umi Guard moderates chat and video.',
        textAlign: TextAlign.center,
        style: ts(11.5, w: FontWeight.w500, c: UC.muted),
      ),
    ],
  );

  Widget _sum(IconData i, String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 14, color: UC.deep),
        const SizedBox(width: 4),
        Text(t, style: ts(12.5, w: FontWeight.w700)),
      ],
    ),
  );

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
