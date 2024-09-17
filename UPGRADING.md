# Upgrade guide

# Upgrading from 2.x to 3.x

The Moments API has been removed. Please use the [Tracing API](https://embrace.io/docs/flutter/features/tracing/) instead.

The Android and iOS SDKs have been updated to the latest major version. If you have written Android/iOS code as part of your integration you may need to perform additional migrations. Please see the [Android](https://embrace.io/docs/android/upgrading/) and [iOS](https://embrace.io/docs/ios/open-source/upgrade-guide/) upgrading guides for further information.

# Upgrading from 1.5.0 to 2.0.0

The methods mark as deprecated in 1.5.0 have been removed from this release.

Please make sure not to have a hardcoded version of the Android SDK in the build.gradle file of your Android project. The correct way to include the Embrace Android SDK is using the `emb_android_sdk` like this:

```
buildscript {

    dependencies {
        classpath "io.embrace:embrace-swazzler:${findProject(':embrace_android').properties['emb_android_sdk']}"
    }
}
```

Please refer to the [Android setup guide](http://https://embrace.io/docs/flutter/integration/add-embrace-sdk/#android-setup) for further information.

# Upgrading from 1.4.0 to 1.5.0

Version 1.5.0 of the Embrace Flutter SDK renames some functions. This has been done to reduce
confusion & increase consistency across our SDKs.

Functions that have been marked as deprecated will still work as before, but will be removed in
the next major version release. Please upgrade when convenient, and get in touch if you have a
use-case that isn’t supported by the new API.

| Old API                              | New API                                 | Comments                         |
|--------------------------------------|-----------------------------------------|----------------------------------|
| `Embrace.instance.setUserPersona  `  | `Embrace.instance.addUserPersona`       | Renamed function for consistency |
| `Embrace.instance.endStartupMoment`  | `Embrace.instance.endAppStartup`        | Renamed function for consistency |
| `Embrace.instance.logBreadcrumb`     | `Embrace.instance.addBreadcrumb`        | Renamed function for consistency |
| `Embrace.instance.logNetworkRequest` | `Embrace.instance.recordNetworkRequest` | Renamed function for consistency |
