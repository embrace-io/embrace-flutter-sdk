/// Class that represents a version of the Embrace SDK
class SdkVersion {
  /// SdkVersion
  SdkVersion(String sdkVersionStr) {
    final version = sdkVersionStr.split('.');
    if (version.isNotEmpty) {
      major = int.tryParse(version[0]) ?? -1;
    }
    if (version.length > 1) {
      minor = int.tryParse(version[1]) ?? -1;
    }
    if (version.length > 2) {
      patch = int.tryParse(version[2]) ?? -1;
    }
  }

  /// Major version
  int major = -1;

  /// Minor version
  int minor = -1;

  /// Patch version
  int patch = -1;

  /// Returns true if sdkVersionStr is lower than this version, false if it
  /// is equal or higher
  bool isLowerThan(String sdkVersionStr) {
    final sdkVersion = SdkVersion(sdkVersionStr);
    if (major > sdkVersion.major) {
      return false;
    } else if (major == sdkVersion.major) {
      if (minor > sdkVersion.minor) {
        return false;
      } else if (minor == sdkVersion.minor) {
        return patch < sdkVersion.patch;
      }
    }
    return true;
  }
}
