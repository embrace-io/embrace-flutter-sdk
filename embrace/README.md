# Embrace SDK for Flutter

In addition to installing the SDK, you'll need to create an Embrace login to see data in our [dashboard](https://embrace.io/). 

# Integration

## Dart setup

Add the Embrace package to your `pubspec.yaml`.

```sh
flutter pub add embrace
```

Wrap the entire contents of your Dart’s main function in `Embrace.instance.start()`. It is essential to wrap the entire contents of `main()` if you want Embrace to capture Dart errors.

```dart
Future<void> main() async {
  await Embrace.instance.start(() => runApp(const MyApp()));
}
```

Perform additional setup for Android & iOS as described below.

## iOS setup

Add the following to `AppDelegate.m`:

```objective-c
#import AppDelegate.h
#import <Embrace/Embrace.h>
@implementation AppDelegate
- (BOOL)application:(UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
[[Embrace sharedInstance] startWithLaunchOptions:launchOptions framework:EMBAppFrameworkFlutter];
    /*
    Initialize additional crash reporters and
    any other libraries to track *after* Embrace, including
    network libraries, 3rd party SDKs
    */
  return YES;
}
@end
```

<details>
  <summary> Swift version</summary>

```swift
import UIKit
import Flutter
import Embrace

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  Embrace.sharedInstance().start(launchOptions: launchOptions, framework: EMBAppFramework.flutter)
  /*
      Initialize additional crash reporters and
      any other libraries to track *after* Embrace, including
      network libraries, 3rd party SDKs
  */
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
}

```

</details>

On the Xcode Build Phase tab, add a new run script. You can find your 5-character app ID and API token in the Embrace dashboard:

```sh
EMBRACE_ID=YOUR_APP_ID EMBRACE_TOKEN=YOUR_API_TOKEN "${PODS_ROOT}/EmbraceIO/run.sh"
```

Create the Embrace-Info.plist configuration file. You can find your 5-character app ID and API token in the Embrace dashboard:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>{YOUR_APP_ID}</string>
    <key>CRASH_REPORT_ENABLED</key>
    <true/>
</dict>
</plist>
```

End the startup moment as close to the point that your UI is ready for use by adding the following to `AppDelegate.m`:

```objective-c
[[Embrace sharedInstance] endAppStartup];
```

## Android setup

In the root-level `build.gradle` Gradle file, add:

```gradle
buildscript {
    repositories {
        mavenCentral()
        google()
    }
    dependencies {
       classpath "io.embrace:embrace-swazzler:${findProject(':embrace_android').properties['emb_android_sdk']}"
    }
```

In the `app/build.gradle` Gradle file, add:

```gradle
apply plugin 'com.android.application'
apply plugin 'embrace-swazzler'
```

In `app/src/main`, add a config file named `embrace-config.json`. You can find your 5-character app ID and API token in the Embrace dashboard:

```json
{
  "app_id": "<your Embrace app ID>",
  "api_token": "<your Embrace API token>",
  "ndk_enabled": true
}
```

In your custom Activity class like in `MyApplication.java`, add:

```java
import io.embrace.android.embracesdk.Embrace;
import android.app.Application;

public final class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        Embrace.getInstance().start(this, false, Embrace.AppFramework.FLUTTER);
    }
}
```

<details>
  <summary> Kotlin version</summary>

```kotlin
import android.os.Bundle
import io.embrace.android.embracesdk.Embrace
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
      super.onCreate(savedInstanceState)
      Embrace.getInstance().start(this, false, Embrace.AppFramework.FLUTTER)
  }
}
```

</details>

If you do not already have a custom `Application` class, create a new source file matching the previous step then edit your `AndroidManifest.xml` to use your new custom Application class. Make sure you edit `AndroidManifest.xml` under the main sourceSet as well as any under debug/other sourceSets:

```xml
<application android:name=".MyApplication">
```

## Verify Your Integration

Build and run your app. The Embrace Dashboard will display the following session data:

- Views and taps
- First-party and third-party network calls (200s, 4xx, 5xx, and connection errors) with timing and call sizes
- Low memory and out-of-memory
- CPU pegging
- Low power mode
- Connectivity (Wifi, cellular, and switches between them)
- Device information (OS version, device, disk usage)
- Crashes
- User terminations

## Tracking navigation automatically

The Embrace SDK can automatically log the start and end of a route by adding the `EmbraceNavigationObserver` to the navigator observers inside your app.

```dart
MaterialApp(
  initialRoute: '/page1',
  home: const Page1(),
  navigatorObservers: [EmbraceNavigationObserver()],
);
```

By default it uses the name in the route settings as the tracked view name. You can customize this by adding a custom `routeSettingsExtractor` method to `EmbraceNavigationObserver`.

## Using in Flutter Tests

You can verify calls to Embrace are correct in unit tests by mocking `Embrace` and setting `debugEmbraceOverride`. This will override `Embrace.instance` in your Flutter code so you are able to capture and verify any calls made to Embrace.

```dart
import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbrace extends Mock implements Embrace {}

void main() {
  testWidgets('button press logs breadcrumb in Embrace', (tester) async {
    final mockEmbrace = MockEmbrace();
    debugEmbraceOverride = mockEmbrace;

    await tester.pumpWidget(
      MaterialApp(
        home: ElevatedButton(
          onPressed: () {
            Embrace.instance.logBreadcrumb('Button pressed');
          },
          child: const Text('Press Me!'),
        ),
      ),
    );

    await tester.tap(find.text('Press Me!'));

    verify(() => mockEmbrace.logBreadcrumb('Button pressed')).called(1);
  });
}
```
