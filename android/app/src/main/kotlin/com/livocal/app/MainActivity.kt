package com.livocal.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val channelName = "com.livocal.app/native_channel"

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
        createNotificationChannels()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "createNotificationChannels" -> {
                    createNotificationChannels()
                    result.success(true)
                }
                "stopCallkitVibration" -> {
                    stopVibrator()
                    result.success(true)
                }
                "setCallkitChannelVibration" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    setCallkitVibration(enabled)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // 1. High Priority Channel for Heads-Up / Urgent Chat Messages
            val highChannel = NotificationChannel(
                "livocal_high_importance",
                "High Priority Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Urgent incoming chat messages and translation notifications"
                enableLights(true)
                lightColor = Color.GREEN
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(highChannel)

            // 2. Default Priority Channel for Standard Chat Messages
            val defaultChannel = NotificationChannel(
                "livocal_default",
                "Standard Messages",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Standard incoming chat messages"
                enableLights(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(defaultChannel)

            // 3. Pre-configure CallKit Channel with custom vibration gating support
            val callChannel = notificationManager.getNotificationChannel("callkit_incoming_channel_id")
            if (callChannel == null) {
                val newCallChannel = NotificationChannel(
                    "callkit_incoming_channel_id",
                    "Livocal Incoming Calls",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Incoming voice call notifications"
                    enableLights(true)
                    lightColor = Color.GREEN
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(newCallChannel)
            }
        }
    }

    private fun stopVibrator() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator?.cancel()
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                vibrator?.cancel()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setCallkitVibration(enabled: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = notificationManager.getNotificationChannel("callkit_incoming_channel_id")
            if (channel != null) {
                channel.enableVibration(enabled)
                if (!enabled) {
                    channel.vibrationPattern = longArrayOf(0)
                } else {
                    channel.vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500)
                }
                notificationManager.createNotificationChannel(channel)
            }
            if (!enabled) {
                stopVibrator()
            }
        }
    }
}
