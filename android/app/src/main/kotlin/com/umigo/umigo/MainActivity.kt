package com.umigo.umigo

import com.umigo.umigo.fx.UmiFxChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var fx: UmiFxChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fx = UmiFxChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
