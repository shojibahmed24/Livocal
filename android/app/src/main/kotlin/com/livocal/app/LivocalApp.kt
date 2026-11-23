package com.livocal.app

import android.app.Application

// minSdk is 24, so Android's native multidex support is available and the
// legacy androidx.multidex dependency is not required.
class LivocalApp : Application() {
    override fun onCreate() {
        super.onCreate()
        NativeBridgePlugin.createNotificationChannels(this)
    }
}
