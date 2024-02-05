# Testing changes in the SDK

The [example app](embrace/example/) can be used to test changes in the SDK. Just call `flutter run` with either an iOS or Android device
plugged in and you should be able to test locally.

## Running in release mode

Before shipping a new version of the SDK we should always run the example app in release mode. This can be achieved by `flutter run --release`.

There are substantial differences that mean this is worthwhile testing (development mode uses a Dart VM, release mode uses SO files).

## Testing Android changes

You can test Android changes in our Flutter SDK by altering the dependency in the Flutter package's build.gradle. You can either publish a local artefact with `./gradlew publishToMavenLocal`, or if you need CI to pass - publish a beta as documented in the [Android repo](https://github.com/embrace-io/embrace-android-sdk3#qa-releases).

### Local artefact
1. Publish locally with `./gradlew publishToMavenLocal -Pversion=<your-version-here>`
2. Find `rootProject.allprojects.repositories` in `embrace_android/android/build.gradle` and add `mavenLocal()`
3. Find `allprojects.repositories` in `embrace/example/android/build.gradle` and add `mavenLocal()`
4. Set the correct `embrace-android-sdk` version in both `embrace_android/android/build.gradle` and `embrace/example/android/build.gradle`
5. Run the app in the normal way

### Beta artefact

1. Follow the [Android repo](https://github.com/embrace-io/embrace-android-sdk3#qa-releases) instructions for creating a beta
2. Find `rootProject.allprojects.repositories` in `embrace_android/android/build.gradle` and add `maven {url "https://repo.embrace.io/repository/beta"}`
3. Find `allprojects.repositories` in `embrace/example/android/build.gradle` and add `maven {url "https://repo.embrace.io/repository/beta"}`
4. Set the correct `embrace-android-sdk` version in both `embrace_android/android/build.gradle` and `embrace/example/android/build.gradle`
5. Run the app in the normal way

## Testing iOS changes locally

### Local artefact

You can test changes local changes to the iOS SDK by updating the Flutter project's `podspec` and `Podfile` to point to the local copy.

1. In `embrace_ios/ios/embrace_ios.podspec`, change the dependency on the iOS SDK to `s.dependency 'EmbraceIO-LOCAL'`
2. In `embrace/example/ios/Podfile`, add the following line `pod 'EmbraceIO-LOCAL', :path => 'path/to/ios_sdk'`
3. In `embrace/example/ios`, run the `pod update` command

### Beta artefact

1. Ask the iOS team to publish a beta of the iOS SDK to the `EmbraceIO-DEV` pod
2. In `embrace_ios/ios/embrace_ios.podspec`, change the dependency on the iOS SDK to `s.dependency 'EmbraceIO-DEV'`
3. In `embrace/example/ios/Podfile`, add the following line `pod 'EmbraceIO-DEV'`
4. In `embrace/example/ios`, run the `pod update` command

# Releasing the SDK

0. Bump the Android/iOS dependencies to the latest available stable versions
1. Bump the SDK version according to semver, with `./set_version.sh <your-version-here> && ./verify_versions.sh`
2. Update the Android SDK version in `embrace_android/android/gradle.properties`
3. Update the changelog of all 4 packages with a description of what changed
4. Run the example app on Android + iOS (in release mode) and confirm that a session is captured & appears in the dashboard with useful info
5. Create a PR with all these changes
6. Add the 'release-candidate' label to the PR
7. Merge the PR. If the label has been added, this will automatically publish the packages to pub.dev

# Releasing a beta SDK version

To release a beta version of the SDK you should add a suffix to the version string. For example, `1.3.0-beta01` would be an appropriate name.

Otherwise, the release process will be exactly the same as for a regular release.
