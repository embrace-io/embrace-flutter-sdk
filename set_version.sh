#!/bin/bash
# Run this script in the root of the embrace-flutter_sdk repo to automatically set the version and dpendencies of the 4 packages to the given value
# Depends on yq.

if ! command -v yq &> /dev/null
then
    echo "Script dependency yq could not be found. Please install and add it to your PATH."
    exit 1
fi

if [ $# -ne 1 ]
then
    echo 'Please pass a single parameter representing the new package version'
    exit 1
fi

new_version=$1

declare -r EMBRACE_PUBSPEC_PATH='embrace/pubspec.yaml'
declare -r EMBRACE_PLATFORM_INTERFACE_PUBSPEC_PATH='embrace_platform_interface/pubspec.yaml'
declare -r EMBRACE_ANDROID_PUBSPEC_PATH='embrace_android/pubspec.yaml'
declare -r EMBRACE_IOS_PUBSPEC_PATH='embrace_ios/pubspec.yaml'
declare -r EMBRACE_DIO_PUBSPEC_PATH='embrace_dio/pubspec.yaml'

declare -r PLATFORM_INTERFACE_DEPENDENCY_NAME='.dependencies.embrace_platform_interface'
declare -r ANDROID_DEPENDENCY_NAME='.dependencies.embrace_android'
declare -r IOS_DEPENDENCY_NAME='.dependencies.embrace_ios'
declare -r DIO_DEPENDENCY_NAME='.dependencies.embrace_dio'

set_package_version () {
    local pubspec_path=$1
    yq -e ".version = \"$new_version\"" -i $pubspec_path
}

set_dependency_version () {
    local pubspec_path=$1
    local dependency_name=$2

    yq -e "$dependency_name = \"^$new_version\"" -i $pubspec_path 
}

set_package_version $EMBRACE_PUBSPEC_PATH 
set_package_version $EMBRACE_PLATFORM_INTERFACE_PUBSPEC_PATH
set_package_version $EMBRACE_ANDROID_PUBSPEC_PATH
set_package_version $EMBRACE_IOS_PUBSPEC_PATH
set_package_version $EMBRACE_DIO_PUBSPEC_PATH

set_dependency_version $EMBRACE_PUBSPEC_PATH $PLATFORM_INTERFACE_DEPENDENCY_NAME
set_dependency_version $EMBRACE_PUBSPEC_PATH $ANDROID_DEPENDENCY_NAME
set_dependency_version $EMBRACE_PUBSPEC_PATH $IOS_DEPENDENCY_NAME
set_dependency_version $EMBRACE_ANDROID_PUBSPEC_PATH $PLATFORM_INTERFACE_DEPENDENCY_NAME
set_dependency_version $EMBRACE_IOS_PUBSPEC_PATH $PLATFORM_INTERFACE_DEPENDENCY_NAME

# Delete generated version script and regenerate
cd embrace_platform_interface
rm lib/src/version.dart
dart run build_runner build
cd ..
