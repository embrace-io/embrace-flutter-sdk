package io.embrace.dio.example;

import io.embrace.android.embracesdk.Embrace;
import io.flutter.app.FlutterApplication;

public final class MyApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        Embrace.getInstance().start(this, Embrace.AppFramework.FLUTTER);
    }
}
