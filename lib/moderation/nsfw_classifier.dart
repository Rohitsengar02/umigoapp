// On-device nudity classifier (MobileNetV2 NSFW model from nsfwjs / GantMan, converted to TFLite).
// Native platforms use TFLite; the web build gets a no-op stub.
export 'nsfw_stub.dart' if (dart.library.ffi) 'nsfw_tflite.dart';
