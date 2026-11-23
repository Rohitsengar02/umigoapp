import 'dart:typed_data';

/// Scores for Drawing, Hentai, Neutral, Porn, Sexy.
typedef NsfwScores = Map<String, double>;

class NsfwClassifier {
  static final NsfwClassifier I = NsfwClassifier();
  bool get available => false;
  Future<void> load() async {}

  /// [png] is an encoded image (PNG/JPEG). Returns null when unavailable.
  Future<NsfwScores?> classify(Uint8List png) async => null;
}
