package io.embrace.flutter.example

import android.app.Application
import androidx.multidex.MultiDexApplication
import io.embrace.android.embracesdk.Embrace

class MyApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        Embrace.getInstance().start(this, Embrace.AppFramework.FLUTTER)
    }
}
