import 'package:material_ui/material_ui.dart';

import '../live/fx.dart';
import '../theme.dart';

/// Filter picker: Beauty sliders, colour Looks and AR stickers. Used before going live
/// and during the live. Changes apply to the camera straight away.
Future<void> showFxSheet(BuildContext context, {int tab = 0}) => showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.transparent, // keep the camera visible while picking
  isScrollControlled: true,
  builder: (_) => FxSheet(initialTab: tab),
);

class FxSheet extends StatefulWidget {
  final int initialTab;
  const FxSheet({super.key, this.initialTab = 0});
  @override
  State<FxSheet> createState() => _FxSheetState();
}

class _FxSheetState extends State<FxSheet> {
  late int tab = widget.initialTab;
  final fx = LiveFx.I;

  @override
  void initState() {
    super.initState();
    fx.load();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: fx,
      builder: (context, _) {
        final s = fx.settings;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, pad.bottom + 14),
          decoration: BoxDecoration(
            color: UC.inkA(.86),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(9)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (i, t) in const ['Beauty', 'Looks', 'AR'].indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _TabChip(t, selected: tab == i, onTap: () => setState(() => tab = i)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: s.any ? () => fx.set(const FxSettings()) : null,
                    child: Text(
                      'Reset',
                      style: ts(13, w: FontWeight.w800, c: s.any ? UC.gold : Colors.white38),
                    ),
                  ),
                ],
              ),
              if (!fx.native || fx.engineFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 2),
                  child: Text(
                    fx.engineFailed
                        ? 'Filters could not start on this phone, so your live is shown without them.'
                        : 'Preview only here. On Android phones viewers see your filters too.',
                    style: ts(11.5, w: FontWeight.w600, c: Colors.white60),
                  ),
                ),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: switch (tab) {
                  0 => _beauty(s),
                  1 => _looks(s),
                  _ => _stickers(s),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _beauty(FxSettings s) {
    Widget slider(String label, IconData icon, double v, FxSettings Function(double) make) => Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: ts(12.5, w: FontWeight.w700, c: Colors.white),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: UC.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: v, onChanged: (x) => fx.set(make(x))),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '${(v * 100).round()}',
            textAlign: TextAlign.right,
            style: ts(11.5, w: FontWeight.w800, c: Colors.white70),
          ),
        ),
      ],
    );
    return Column(
      key: const ValueKey('beauty'),
      children: [
        Row(
          children: [
            for (final (label, preset) in [('Off', const FxSettings()), ('Natural', FxSettings.natural), ('Glam', FxSettings.glam)])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TabChip(label, selected: _sameBeauty(s, preset), onTap: () => fx.set(s.withBeauty(preset)), small: true),
              ),
          ],
        ),
        const SizedBox(height: 6),
        slider('Smooth', Icons.blur_on_rounded, s.smooth, (v) => s.copyWith(smooth: v)),
        slider('Brighten', Icons.wb_sunny_outlined, s.whiten, (v) => s.copyWith(whiten: v)),
        slider('Slim face', Icons.face_retouching_natural, s.slim, (v) => s.copyWith(slim: v)),
        slider('Big eyes', Icons.remove_red_eye_outlined, s.eyes, (v) => s.copyWith(eyes: v)),
        slider('Lipstick', Icons.favorite_border_rounded, s.lips, (v) => s.copyWith(lips: v)),
        slider('Blush', Icons.brightness_1_outlined, s.blush, (v) => s.copyWith(blush: v)),
      ],
    );
  }

  bool _sameBeauty(FxSettings a, FxSettings b) =>
      a.smooth == b.smooth && a.whiten == b.whiten && a.slim == b.slim && a.eyes == b.eyes && a.lips == b.lips && a.blush == b.blush;

  Widget _looks(FxSettings s) => SizedBox(
    key: const ValueKey('looks'),
    height: 104,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: kLooks.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final l = kLooks[i];
        final on = s.look == l.id;
        Widget thumb = Image.asset('assets/img/ava.jpg', width: 66, height: 66, fit: BoxFit.cover);
        if (l.matrix != null) thumb = ColorFiltered(colorFilter: ColorFilter.matrix(l.matrix!), child: thumb);
        return GestureDetector(
          onTap: () => fx.set(s.copyWith(look: l.id)),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: on ? UC.primary : Colors.transparent, width: 2.5),
                ),
                child: ClipOval(child: thumb),
              ),
              const SizedBox(height: 5),
              Text(
                l.label,
                style: ts(11.5, w: FontWeight.w800, c: on ? Colors.white : Colors.white70),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _stickers(FxSettings s) => GridView.count(
    key: const ValueKey('ar'),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: .95,
    children: [
      for (final st in kStickers)
        GestureDetector(
          onTap: () => fx.set(s.copyWith(sticker: st.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: s.sticker == st.id ? UC.primary.withValues(alpha: .35) : Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.sticker == st.id ? UC.primary : Colors.transparent, width: 2),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: st.icon == null ? const Icon(Icons.block_rounded, color: Colors.white70, size: 28) : Image.asset(st.icon!, fit: BoxFit.contain),
                ),
                const SizedBox(height: 4),
                Text(
                  st.label,
                  maxLines: 1,
                  style: ts(11, w: FontWeight.w800, c: Colors.white),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected, small;
  final VoidCallback onTap;
  const _TabChip(this.label, {required this.selected, required this.onTap, this.small = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: small ? 30 : 34,
      padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: selected ? Colors.white : Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: ts(small ? 12 : 13, w: FontWeight.w800, c: selected ? UC.ink : Colors.white),
      ),
    ),
  );
}
