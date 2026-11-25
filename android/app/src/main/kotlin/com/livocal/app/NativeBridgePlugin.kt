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

        fun createNotificationChannels(ctx: Context, language: String = "en") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val s = channelStrings(language)

                // 1. High Priority Channel for Heads-Up / Urgent Chat Messages
                val highChannel = NotificationChannel(
                    "livocal_high_importance",
                    s[0],
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = s[1]
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
                    s[2],
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = s[3]
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
                        s[4],
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = s[5]
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

        /**
         * Channel names are user-visible in Android settings, so they follow the
         * app language: [highName, highDesc, defaultName, defaultDesc, callName, callDesc].
         */
        private fun channelStrings(language: String): Array<String> = when (language) {
            "bn" -> arrayOf(
                "উচ্চ গুরুত্বপূর্ণ বার্তা",
                "জরুরি চ্যাট বার্তা ও অনুবাদ নোটিফিকেশন",
                "সাধারণ বার্তা",
                "সাধারণ চ্যাট বার্তা",
                "Livocal ইনকামিং কল",
                "ইনকামিং ভয়েস কল নোটিফিকেশন"
            )
            "hi" -> arrayOf(
                "उच्च प्राथमिकता संदेश",
                "तत्काल चैट संदेश और अनुवाद सूचनाएँ",
                "सामान्य संदेश",
                "सामान्य चैट संदेश",
                "Livocal इनकमिंग कॉल",
                "इनकमिंग वॉइस कॉल सूचनाएँ"
            )
            "ar" -> arrayOf(
                "رسائل عالية الأولوية",
                "رسائل دردشة عاجلة وإشعارات الترجمة",
                "رسائل عادية",
                "رسائل دردشة عادية",
                "مكالمات Livocal الواردة",
                "إشعارات المكالمات الصوتية الواردة"
            )
            "es" -> arrayOf(
                "Mensajes prioritarios",
                "Mensajes urgentes y avisos de traducción",
                "Mensajes estándar",
                "Mensajes de chat estándar",
                "Llamadas entrantes de Livocal",
                "Avisos de llamadas de voz entrantes"
            )
            "fr" -> arrayOf(
                "Messages prioritaires",
                "Messages urgents et notifications de traduction",
                "Messages standard",
                "Messages de discussion standard",
                "Appels entrants Livocal",
                "Notifications d'appels vocaux entrants"
            )
            "de" -> arrayOf(
                "Wichtige Nachrichten",
                "Dringende Chat-Nachrichten und Übersetzungshinweise",
                "Standardnachrichten",
                "Normale Chat-Nachrichten",
                "Eingehende Livocal-Anrufe",
                "Hinweise zu eingehenden Sprachanrufen"
            )
            else -> arrayOf(
                "High Priority Messages",
                "Urgent incoming chat messages and translation notifications",
                "Standard Messages",
                "Standard incoming chat messages",
                "Livocal Incoming Calls",
                "Incoming voice call notifications"
            )
        }
    }

    /**
     * Reads the Flutter-owned SharedPreferences so the very first launch (before
     * any MethodChannel call) can still create localized channels.
     */
    private fun currentAppLanguage(): String = try {
        context
            ?.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            ?.getString("flutter.app_language", "en")
            ?: "en"
    } catch (_: Exception) {
        "en"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        instance = this
        createNotificationChannels(binding.applicationContext, currentAppLanguage())
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
                val language = call.argument<String>("language")
                    ?: currentAppLanguage()
                createNotificationChannels(ctx, language)
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
