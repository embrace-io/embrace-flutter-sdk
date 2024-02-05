#!/bin/bash
# Run this script in the root of the embrace-flutter-sdk repo to verify that all package versions and dependencies match
# Depends on yq.

if ! command -v yq &> /dev/null
then
    echo "Script dependency yq could not be found. Please install and add it to your PATH."
    exit 1
fi

error_count=0

# Verifies that the versions defined in two pubspec files are the same.
# Arguments:
#   $1 path to pubspec_a
#   $2 path to pbuspec_b
verify_versions_match () {
    local pubspec_a=$1
    local pubspec_b=$2
    local version_a=$(yq -e '.version' $pubspec_a)
    local version_b=$(yq -e '.version' $pubspec_b)

    if [ $version_a != $version_b ]
    then
        echo "$pubspec_a version ($version_a) does not match $pubspec_b version ($version_b)"
        let "error_count+=1"
    fi
}

# Verifies that the version specified in a dependency is equal to the current version of the dependency target
# Arguments:
#   $1 path to the pubspec that contains the dependency
#   $2 qualified name of the dependency, ie .dependencies.embrace_android
#   $3 path to the pubspec of the target package of the dependency
verify_dependency () {
    local dependency_pubspec=$1
    local dependency_name=$2
    local target_pubspec=$3

    local target_version=$(yq -e '.version' $target_pubspec)
    local dependency_version=$(yq -e $dependency_name $dependency_pubspec)

    if [[ $dependency_version != '>='$target_version* ]]
    then
        echo "$dependency_pubspec dependency on $dependency_name ($dependency_version) does not match $target_pubspec version ($target_version)"
        let "error_count+=1"
    fi
}

declare -r EMBRACE_PUBSPEC_PATH='embrace/pubspec.yaml'
declare -r EMBRACE_PLATFORM_INTERFACE_PUBSPEC_PATH='embrace_platform_interface/pubspec.yaml'
declare -r EMBRACE_ANDROID_PUBSPEC_PATH='embrace_android/pubspec.yaml'
declare -r EMBRACE_IOS_PUBSPEC_PATH='embrace_ios/pubspec.yaml'
declare -r EMBRACE_DIO_PUBSPEC_PATH='embrace_dio/pubspec.yaml'

declare -r EMBRACE_DEPENDENCY_NAME='.dependencies.embrace'
declare -r PLATFORM_INTERFACE_DEPENDENCY_NAME='.dependencies.embrace_platform_interface'
declare -r ANDROID_DEPENDENCY_NAME='.dependencies.embrace_android'
declare -r IOS_DEPENDENCY_NAME='.dependencies.embrace_ios'
declare -r DIO_DEPENDENCY_NAME='.dependencies.embrace_dio'

# Verify versions of all 5 packages are the same
verify_versions_match $EMBRACE_PUBSPEC_PATH $EMBRACE_PLATFORM_INTERFACE_PUBSPEC_PATH
verify_versions_match $EMBRACE_PUBSPEC_PATH $EMBRACE_ANDROID_PUBSPEC_PATH
verify_versions_match $EMBRACE_PUBSPEC_PATH $EMBRACE_IOS_PUBSPEC_PATH
verify_versions_match $EMBRACE_PUBSPEC_PATH $EMBRACE_DIO_PUBSPEC_PATH

# Verify dependencies match current package versions
verify_dependency $EMBRACE_PUBSPEC_PATH $PLATFORM_INTERFACE_DEPENDENCY_NAME $EMBRACE_PLATFORM_INTERFACE_PUBSPEC_PATH
verify_dependency $EMBRACE_PUBSPEC_PATH $ANDROID_DEPENDENCY_NAME $EMBRACE_ANDROID_PUBSPEC_PATH
verify_dependency $EMBRACE_PUBSPEC_PATH $IOS_DEPENDENCY_NAME $EMBRACE_IOS_PUBSPEC_PATH
verify_dependency $EMBRACE_ANDROID_PUBSPEC_PATH $PLATFORM_INTERFACE_DEPENDENCY_NAME $EMBRACE_PLATFORM_INTERFACE_PUBSPEC_PATH
verify_dependency $EMBRACE_IOS_PUBSPEC_PATH $PLATFORM_INTERFACE_DEPENDENCY_NAME $EMBRACE_PLATFORM_INTERFACE_PUBSPEC_PATH

# Verify version in generated script is the same
declare -r GENERATED_VERSION_SCRIPT_PATH=embrace_platform_interface/lib/src/version.dart
generated_version=$(sed -n "s/^.*'\(.*\)'.*$/\1/ p" $GENERATED_VERSION_SCRIPT_PATH) 
package_version=$(yq -e '.version' $EMBRACE_PUBSPEC_PATH)
if [ $generated_version != $package_version ]
then
    echo "Generated version ($generated_version) in version.dart does not match package version ($package_version)"
    let "error_count+=1"
fi


if [ $error_count -gt 0 ]
then
    exit 1
fi

echo 'All package versions and dependencies match'
exit 0