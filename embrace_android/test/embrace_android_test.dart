import 'package:embrace_android/embrace_android.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmbraceAndroid', () {
    const kDeviceId = 'Android';
    late EmbraceAndroid embrace;
    late List<MethodCall> log;

    setUp(() async {
      embrace = EmbraceAndroid();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(embrace.methodChannel, (methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getDeviceId':
            return kDeviceId;
          default:
            return null;
        }
      });
    });

    test('can be registered', () {
      EmbraceAndroid.registerWith();
      expect(EmbracePlatform.instance, isA<EmbraceAndroid>());
    });

    test('getDeviceId returns correct value', () async {
      final name = await embrace.getDeviceId();
      expect(
        log,
        <Matcher>[isMethodCall('getDeviceId', arguments: null)],
      );
      expect(name, equals(kDeviceId));
    });
  });
}
