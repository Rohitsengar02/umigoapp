package com.umigo.umigo.fx

import android.content.Context
import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import com.cloudwebrtc.webrtc.video.LocalVideoTrack
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** "umigo/fx": attach the filter to a camera track and change its settings from Dart. */
class UmiFxChannel(context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val fx = UmiFx(context)
    private var track: LocalVideoTrack? = null
    private val channel = MethodChannel(messenger, "umigo/fx")

    init {
        channel.setMethodCallHandler(this)
        Thread({ fx.init() }, "umigo-fx-init").start()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(mapOf("ready" to fx.ready, "failed" to fx.failed, "error" to fx.lastError))
            "attach" -> {
                val id = call.argument<String>("trackId")
                val t = id?.let { FlutterWebRTCPlugin.sharedSingleton?.getLocalTrack(it) } as? LocalVideoTrack
                if (t == null) {
                    result.success(false)
                    return
                }
                if (t !== track) {
                    track?.removeProcessor(fx)
                    t.addProcessor(fx)
                    track = t
                }
                result.success(true)
            }
            "detach" -> {
                track?.removeProcessor(fx)
                track = null
                result.success(true)
            }
            "update" -> {
                (call.arguments as? Map<*, *>)?.let { fx.settings = FxSettings.from(it) }
                result.success(fx.ready && !fx.failed)
            }
            else -> result.notImplemented()
        }
    }
}
