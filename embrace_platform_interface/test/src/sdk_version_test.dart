import 'package:embrace_platform_interface/src/sdk_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parse a string correctly in the constructor', () {
    test('Parse a full string', () {
      final sdkVersion = SdkVersion('0.1.2');
      expect(sdkVersion.major, 0);
      expect(sdkVersion.minor, 1);
      expect(sdkVersion.patch, 2);
    });

    test('Parse a string with missing minor and patch', () {
      final sdkVersion = SdkVersion('0');
      expect(sdkVersion.major, 0);
      expect(sdkVersion.minor, -1);
      expect(sdkVersion.patch, -1);
    });

    test('Parse a string with missing patch', () {
      final sdkVersion = SdkVersion('0.1');
      expect(sdkVersion.major, 0);
      expect(sdkVersion.minor, 1);
      expect(sdkVersion.patch, -1);
    });

    test('Parse a malformed string', () {
      final sdkVersion = SdkVersion('null');
      expect(sdkVersion.major, -1);
      expect(sdkVersion.minor, -1);
      expect(sdkVersion.patch, -1);
    });
  });

  group('Version compare', () {
    test('Lower version', () {
      final sdkVersion = SdkVersion('0.1.2');
      expect(sdkVersion.isLowerThan('1.0.0'), isTrue);
      expect(sdkVersion.isLowerThan('0.2.0'), isTrue);
      expect(sdkVersion.isLowerThan('0.1.3'), isTrue);
    });

    test('Equal version', () {
      final sdkVersion = SdkVersion('0.1.2');
      expect(sdkVersion.isLowerThan('0.1.2'), isFalse);
    });

    test('Higher version', () {
      final sdkVersion = SdkVersion('0.1.2');
      expect(sdkVersion.isLowerThan('0.1.1'), isFalse);
      expect(sdkVersion.isLowerThan('0.0.2'), isFalse);
      expect(sdkVersion.isLowerThan('0.0.1'), isFalse);
    });
  });
}
