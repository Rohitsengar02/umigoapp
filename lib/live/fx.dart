import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Camera filters the creator picks: beauty, a colour look and an AR sticker.
/// Strengths are 0..1.
@immutable
class FxSettings {
  final double smooth, whiten, slim, eyes, lips, blush;
  final String look, sticker;
  const FxSettings({
    this.smooth = 0,
    this.whiten = 0,
    this.slim = 0,
    this.eyes = 0,
    this.lips = 0,
    this.blush = 0,
    this.look = 'none',
    this.sticker = 'none',
  });

  static const natural = FxSettings(smooth: .55, whiten: .3, slim: .25, eyes: .15);
  static const glam = FxSettings(smooth: .75, whiten: .45, slim: .4, eyes: .3, lips: .55, blush: .45);

  bool get any => smooth > 0 || whiten > 0 || slim > 0 || eyes > 0 || lips > 0 || blush > 0 || look != 'none' || sticker != 'none';
  bool get beautyOn => smooth > 0 || whiten > 0 || slim > 0 || eyes > 0 || lips > 0 || blush > 0;

  FxSettings copyWith({double? smooth, double? whiten, double? slim, double? eyes, double? lips, double? blush, String? look, String? sticker}) => FxSettings(
    smooth: smooth ?? this.smooth,
    whiten: whiten ?? this.whiten,
    slim: slim ?? this.slim,
    eyes: eyes ?? this.eyes,
    lips: lips ?? this.lips,
    blush: blush ?? this.blush,
    look: look ?? this.look,
    sticker: sticker ?? this.sticker,
  );

  /// Keeps the look and sticker, swaps the beauty values.
  FxSettings withBeauty(FxSettings b) => b.copyWith(look: look, sticker: sticker);

  Map<String, Object> toJson() => {
    'smooth': smooth,
    'whiten': whiten,
    'slim': slim,
    'eyes': eyes,
    'lips': lips,
    'blush': blush,
    'look': look,
    'sticker': sticker,
  };

  static FxSettings fromJson(Map<String, dynamic> j) {
    double d(String k) => ((j[k] as num?) ?? 0).toDouble().clamp(0, 1).toDouble();
    return FxSettings(
      smooth: d('smooth'),
      whiten: d('whiten'),
      slim: d('slim'),
      eyes: d('eyes'),
      lips: d('lips'),
      blush: d('blush'),
      look: '${j['look'] ?? 'none'}',
      sticker: '${j['sticker'] ?? 'none'}',
    );
  }

  @override
  bool operator ==(Object other) => other is FxSettings && jsonEncode(other.toJson()) == jsonEncode(toJson());
  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// A colour look: id, label, and a colour matrix used for the thumbnail (and as the
/// preview on platforms where the real filter engine is not available).
typedef FxLook = ({String id, String label, List<double>? matrix});

List<double> _sat(double s) {
  const r = .2126, g = .7152, b = .0722;
  return [
    r * (1 - s) + s, g * (1 - s), b * (1 - s), 0, 0, //
    r * (1 - s), g * (1 - s) + s, b * (1 - s), 0, 0,
    r * (1 - s), g * (1 - s), b * (1 - s) + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

const List<double> _warm = [1.08, 0, 0, 0, 8, 0, 1.0, 0, 0, 2, 0, 0, .88, 0, -6, 0, 0, 0, 1, 0];
const List<double> _cool = [.92, 0, 0, 0, -4, 0, 1.0, 0, 0, 0, 0, 0, 1.1, 0, 10, 0, 0, 0, 1, 0];
const List<double> _vintage = [.75, .2, .1, 0, 14, .15, .72, .1, 0, 10, .1, .15, .55, 0, 6, 0, 0, 0, 1, 0];
const List<double> _sketch = [.5, .5, .5, 0, 40, .5, .5, .5, 0, 40, .5, .5, .5, 0, 40, 0, 0, 0, 1, 0];
const List<double> _toon = [1.3, 0, 0, 0, -10, 0, 1.3, 0, 0, -10, 0, 0, 1.3, 0, -10, 0, 0, 0, 1, 0];

final List<FxLook> kLooks = [
  (id: 'none', label: 'Original', matrix: null),
  (id: 'warm', label: 'Warm', matrix: _warm),
  (id: 'cool', label: 'Cool', matrix: _cool),
  (id: 'vivid', label: 'Vivid', matrix: _sat(1.45)),
  (id: 'vintage', label: 'Vintage', matrix: _vintage),
  (id: 'mono', label: 'B&W', matrix: _sat(0)),
  (id: 'sketch', label: 'Sketch', matrix: _sketch),
  (id: 'toon', label: 'Toon', matrix: _toon),
];

/// AR face stickers: id, label, and the picture shown in the picker.
const List<({String id, String label, String? icon})> kStickers = [
  (id: 'none', label: 'None', icon: null),
  (id: 'glasses', label: 'Shades', icon: 'assets/fx/glasses.png'),
  (id: 'star', label: 'Star eyes', icon: 'assets/fx/star_glasses.png'),
  (id: 'crown', label: 'Crown', icon: 'assets/fx/crown.png'),
  (id: 'cat', label: 'Kitty', icon: 'assets/fx/cat_ears.png'),
  (id: 'bunny', label: 'Bunny', icon: 'assets/fx/bunny_ears.png'),
  (id: 'hearts', label: 'Hearts', icon: 'assets/fx/hearts.png'),
];

/// The filter engine. On Android the filters run on every camera frame before it is
/// sent (GPUPixel, see android/app/.../fx/UmiFx.kt), so viewers see them too.
/// Elsewhere only a colour preview is shown on the creator's own screen.
class LiveFx extends ChangeNotifier {
  LiveFx._();
  static final LiveFx I = LiveFx._();
  static const _ch = MethodChannel('umigo/fx');

  FxSettings settings = const FxSettings();
  bool engineFailed = false;
  String? engineError;
  bool _loaded = false;

  bool get native => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString('fx');
      if (raw != null) settings = FxSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
    notifyListeners();
  }

  void set(FxSettings s) {
    if (s == settings) return;
    settings = s;
    notifyListeners();
    _push();
    SharedPreferences.getInstance().then((p) => p.setString('fx', jsonEncode(s.toJson()))).catchError((_) => false);
  }

  Future<void> _push() async {
    if (!native) return;
    try {
      final ok = await _ch.invokeMethod<bool>('update', settings.toJson());
      if (ok == false) await _status();
    } catch (_) {}
  }

  Future<void> _status() async {
    try {
      final m = await _ch.invokeMapMethod<String, Object?>('status');
      final failed = m?['failed'] == true;
      if (failed != engineFailed) {
        engineFailed = failed;
        engineError = m?['error'] as String?;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Run the filters on this camera track. Call again after the camera is flipped or
  /// restarted, since that makes a new native track.
  Future<bool> attach(LocalVideoTrack? t) async {
    if (!native || t == null) return false;
    await load();
    try {
      await _ch.invokeMethod('update', settings.toJson());
      final ok = await _ch.invokeMethod<bool>('attach', {'trackId': t.mediaStreamTrack.id});
      await _status();
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> detach() async {
    if (!native) return;
    try {
      await _ch.invokeMethod('detach');
    } catch (_) {}
  }

  /// Wraps the creator's own preview. On Android the frames are already filtered,
  /// so this only tints the preview where the engine does not run.
  Widget preview(Widget child) {
    if (native && !engineFailed) return child;
    final m = kLooks.where((l) => l.id == settings.look).firstOrNull?.matrix;
    if (m == null) return child;
    return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
  }
}
