import 'package:embrace_platform_interface/src/otel/embrace_resource.dart';
import 'package:embrace_platform_interface/src/version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  group('buildEmbraceResource', () {
    test('includes service.name as embrace-flutter', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      expect(attrs.getString('service.name'), 'embrace-flutter');
    });

    test('includes service.version matching packageVersion', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      expect(attrs.getString('service.version'), packageVersion);
    });

    test('includes telemetry.sdk.name as embrace-flutter', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      expect(attrs.getString('telemetry.sdk.name'), 'embrace-flutter');
    });

    test('includes telemetry.sdk.version matching packageVersion', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      expect(attrs.getString('telemetry.sdk.version'), packageVersion);
    });

    test('includes os.name from platform', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      expect(attrs.getString('os.name'), 'android');
    });

    test('sets os.type to android for Android platform', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      expect(attrs.getString('os.type'), 'android');
    });

    test('sets os.type to ios for iOS platform', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'ios'),
      );
      expect(attrs.getString('os.type'), 'ios');
    });

    test('omits os.type for unsupported platforms', () {
      final attrs = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'linux'),
      );
      expect(attrs.getString('os.type'), isNull);
    });

    test('is built lazily — each call returns a fresh Attributes instance', () {
      final attrs1 = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      final attrs2 = buildEmbraceResource(
        platform: FakePlatform(operatingSystem: 'ios'),
      );
      expect(attrs1.getString('os.type'), 'android');
      expect(attrs2.getString('os.type'), 'ios');
    });
  });
}
