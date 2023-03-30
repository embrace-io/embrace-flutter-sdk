package io.embrace.flutter.example;

import android.app.Application;
import androidx.multidex.MultiDexApplication;
import io.embrace.android.embracesdk.Embrace;

public final class MyApplication extends MultiDexApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        Embrace.getInstance().start(this, false, Embrace.AppFramework.FLUTTER);
    }
}
