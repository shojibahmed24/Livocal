package com.livocal.app

import androidx.multidex.MultiDexApplication

class LivocalApp : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        NativeBridgePlugin.createNotificationChannels(this)
    }
}
