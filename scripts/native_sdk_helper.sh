#!/bin/bash

#
# Wrapper script to help with updating native Embrace SDK versions.
# It is primarily used by .github/workflows/update-native-sdks.yaml and not humans.
#

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <get|set> <android|apple> [version]"
  exit 1
fi

action=$1   # get or set
platform=$2 # example: android or apple
version=$3  # only for "set"

if [[ $action == "get" ]]; then
  if [[ $platform == "android" ]]; then
    grep "emb_android_sdk=" embrace_android/android/gradle.properties | cut -f 2 -d=
    exit 0
  fi

  if [[ $platform == "apple" ]]; then
    grep "s.dependency 'EmbraceIO'" embrace_ios/ios/embrace_ios.podspec | cut -f 4 -d\'
    exit 0
  fi
fi

if [[ $action == "set" ]]; then
  if [[ $(uname) == "Darwin" ]]; then
    SED=gsed
  else
    SED=sed
  fi

  # Example: https://github.com/embrace-io/embrace-flutter-sdk/pull/84
  if [[ $platform == "android" ]]; then
    $SED -i "s/^emb_android_sdk=.*/emb_android_sdk=${version}/" embrace_android/android/gradle.properties
    $SED -i "s/static const String minimumAndroidVersion = '.*'/static const String minimumAndroidVersion = '${version}'/" embrace_platform_interface/lib/method_channel_embrace.dart
  fi

  # Example: https://github.com/embrace-io/embrace-flutter-sdk/pull/83/files#diff-e5d0042a93a4077ef0e0faeab47e4ecdddbdae595a19d7804934b7db1c0e7164
  if [[ $platform == "apple" ]]; then
    $SED -i "s/s.dependency 'EmbraceIO', '.*'/s.dependency 'EmbraceIO', '${version}'/" embrace_ios/ios/embrace_ios.podspec
  fi
fi
