import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/src/version.dart';
import 'package:platform/platform.dart';

/// Builds the OTel [Attributes] describing the Embrace Flutter SDK resource.
///
/// The attributes are constructed lazily each time this function is called —
/// nothing is computed at import time. This is an internal utility and is not
/// part of the public API.
///
/// The returned [Attributes] always include:
/// - `service.name`: `"embrace-flutter"`
/// - `service.version`: the current SDK version from [packageVersion]
/// - `telemetry.sdk.name`: `"embrace-flutter"`
/// - `telemetry.sdk.version`: the current SDK version from [packageVersion]
/// - `os.name`: raw OS identifier from [Platform.operatingSystem]
///
/// When the platform is Android or iOS, `os.type` is also included using the
/// OTel semantic convention value (`"android"` or `"ios"`).
///
/// [platform] may be supplied to override the default [LocalPlatform], which
/// is useful in tests.
Attributes buildEmbraceResource({Platform? platform}) {
  final resolvedPlatform = platform ?? const LocalPlatform();
  final attributes = <String, Object>{
    'service.name': 'embrace-flutter',
    'service.version': packageVersion,
    'telemetry.sdk.name': 'embrace-flutter',
    'telemetry.sdk.version': packageVersion,
    'os.name': resolvedPlatform.operatingSystem,
  };

  if (resolvedPlatform.isAndroid) {
    attributes['os.type'] = 'android';
  } else if (resolvedPlatform.isIOS) {
    attributes['os.type'] = 'ios';
  }

  return Attributes.of(attributes);
}
