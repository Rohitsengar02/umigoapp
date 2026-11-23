# GPUPixel (vendored)

Camera filter engine for Umigo's live filters, from https://github.com/pixpark/gpupixel
(commit ef552bf, Apache-2.0, see `native/LICENSE`). Only the parts Android needs are kept:
`native/` (C++ core, JNI, libyuv, stb, ghc, Mars face kit for ARM) and the Java wrapper.

Changes for Umigo:
- `src/main/java/.../GPUPixel.java`: `i420ToRgba()` helper, and skips Flutter's own assets when copying models.
- `native/src/filter/filter.cc`: registers Grayscale, Contrast, Saturation, WhiteBalance, SmoothToon and Sketch for the looks.
- `build.gradle.kts`: Gradle Kotlin DSL module built with the app's NDK.

The app side is `android/app/src/main/kotlin/com/umigo/umigo/fx/`.
