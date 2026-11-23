import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Scores for Drawing, Hentai, Neutral, Porn, Sexy.
typedef NsfwScores = Map<String, double>;

const _labels = ['Drawing', 'Hentai', 'Neutral', 'Porn', 'Sexy'];

class NsfwClassifier {
  static final NsfwClassifier I = NsfwClassifier();
  IsolateInterpreter? _iso;
  Interpreter? _interp;
  Future<void>? _loading;
  bool get available => _iso != null;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final opts = InterpreterOptions()..threads = 2;
      _interp = await Interpreter.fromAsset('assets/models/nsfw_mobilenet_v2.tflite', options: opts);
      _iso = await IsolateInterpreter.create(address: _interp!.address);
    } catch (_) {
      _iso = null; // model could not load (e.g. unsupported CPU); moderation falls back to chat only
    }
  }

  /// Decodes and resizes off the UI thread, then runs the model in its own isolate.
  Future<NsfwScores?> classify(Uint8List encoded) async {
    await load();
    final iso = _iso;
    if (iso == null) return null;
    final input = await Isolate.run(() => _prepare(encoded));
    if (input == null) return null;
    final out = [List<double>.filled(5, 0)];
    await iso.run(input.reshape([1, 224, 224, 3]), out);
    return {for (var i = 0; i < 5; i++) _labels[i]: out[0][i]};
  }

  static Float32List? _prepare(Uint8List encoded) {
    final decoded = img.decodeImage(encoded);
    if (decoded == null) return null;
    final small = img.copyResize(decoded, width: 224, height: 224, interpolation: img.Interpolation.linear);
    final f = Float32List(224 * 224 * 3);
    var i = 0;
    for (final p in small) {
      f[i++] = p.r / 255.0;
      f[i++] = p.g / 255.0;
      f[i++] = p.b / 255.0;
    }
    return f;
  }
}
