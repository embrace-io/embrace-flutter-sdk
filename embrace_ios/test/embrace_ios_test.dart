import 'package:embrace_ios/embrace_ios.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmbraceIOS', () {
    const kDeviceId = 'iOS';
    late EmbraceIOS embrace;
    late List<MethodCall> log;

    setUp(() async {
      embrace = EmbraceIOS();

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
      EmbraceIOS.registerWith();
      expect(EmbracePlatform.instance, isA<EmbraceIOS>());
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
