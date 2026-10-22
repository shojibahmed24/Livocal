package com.livocal.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class NativeBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var suppressionJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    companion object {
        const val CHANNEL_NAME = "com.livocal.app/native_channel"
        var instance: NativeBridgePlugin? = null
            private set

        fun stopVibrator(ctx: Context) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vibratorManager = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                    vibratorManager?.defaultVibrator?.cancel()
                } else {
                    @Suppress("DEPRECATION")
                    val vibrator = ctx.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                    vibrator?.cancel()
                }
            } catch (_: Exception) {}
        }

        fun createNotificationChannels(ctx: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

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

                // 3. CallKit Channel: Configure with enableVibration(false) and vibrationPattern = [0]
                // Dynamic hardware vibration is controlled strictly via CallkitSoundPlayerService / NativeBridge
                val existingCallChannel = notificationManager.getNotificationChannel("callkit_incoming_channel_id")
                if (existingCallChannel == null || existingCallChannel.shouldVibrate()) {
                    if (existingCallChannel != null) {
                        try {
                            notificationManager.deleteNotificationChannel("callkit_incoming_channel_id")
                        } catch (_: Exception) {}
                    }
                    val newCallChannel = NotificationChannel(
                        "callkit_incoming_channel_id",
                        "Livocal Incoming Calls",
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "Incoming voice call notifications"
                        enableLights(true)
                        lightColor = Color.GREEN
                        enableVibration(false)
                        vibrationPattern = longArrayOf(0)
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    }
                    notificationManager.createNotificationChannel(newCallChannel)
                }
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        instance = this
        createNotificationChannels(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        if (instance == this) {
            instance = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.success(false)
            return
        }
        when (call.method) {
            "createNotificationChannels" -> {
                createNotificationChannels(ctx)
                result.success(true)
            }
            "stopCallkitVibration" -> {
                startVibrationSuppression(ctx, durationMs = 15000L)
                result.success(true)
            }
            "cancelVibrationSuppression" -> {
                stopVibrationSuppression()
                result.success(true)
            }
            "setCallkitChannelVibration" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                if (!enabled) {
                    startVibrationSuppression(ctx, durationMs = 15000L)
                } else {
                    stopVibrationSuppression()
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    fun startVibrationSuppression(ctx: Context, durationMs: Long = 15000L) {
        stopVibrator(ctx)
        suppressionJob?.cancel()
        suppressionJob = scope.launch {
            val endTime = System.currentTimeMillis() + durationMs
            while (System.currentTimeMillis() < endTime && isActive) {
                stopVibrator(ctx)
                delay(50)
            }
        }
    }

    fun stopVibrationSuppression() {
        suppressionJob?.cancel()
        suppressionJob = null
    }
}
