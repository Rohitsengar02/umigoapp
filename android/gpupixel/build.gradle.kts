// GPUPixel (Apache-2.0, https://github.com/pixpark/gpupixel) built from source for the
// live camera filters: beauty, face reshape, lipstick, blush and colour looks, plus the
// Mars face kit (106 face points) used to place AR stickers.
plugins {
    id("com.android.library")
}

android {
    namespace = "com.pixpark.gpupixel"
    compileSdk = 37
    ndkVersion = "28.2.13676358" // same NDK as the Flutter app

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17"
                arguments += listOf("-DANDROID_STL=c++_shared", "-DGPUPIXEL_INSTALL=OFF")
            }
        }
        ndk {
            // the face kit ships for ARM phones only
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDir("native/third_party/mars-face-kit/libs/android")
            assets.srcDir("native/third_party/mars-face-kit/models")
            assets.srcDir("native/src/res")
        }
    }

    packaging {
        jniLibs {
            excludes += "lib/*/libyuv.so"
            pickFirsts += "lib/*/libmars-face-kit.so"
            pickFirsts += "lib/*/libc++_shared.so"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    externalNativeBuild {
        cmake {
            path = file("native/CMakeLists.txt")
            version = "3.22.1"
        }
    }
}
