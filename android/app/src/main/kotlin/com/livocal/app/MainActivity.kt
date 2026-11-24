package com.livocal.app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private var secureScreenChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        NativeBridgePlugin.createNotificationChannels(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ensure NativeBridgePlugin is registered on main engine
        if (!flutterEngine.plugins.has(NativeBridgePlugin::class.java)) {
            flutterEngine.plugins.add(NativeBridgePlugin())
        }

        // Screenshot / screen-recording protection (FLAG_SECURE), toggled from Dart
        secureScreenChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.livocal.app/secure_screen"
        )
        secureScreenChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "disable" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        secureScreenChannel?.setMethodCallHandler(null)
        secureScreenChannel = null
        super.onDestroy()
    }
}
