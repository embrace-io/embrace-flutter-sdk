import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/embrace.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/embrace_otel_factory.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEmbracePlatform platform;

  setUp(() {
    platform = MockEmbracePlatform();
    EmbracePlatform.instance = platform;
    when(
      () => platform.attachToHostSdk(
        enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
      ),
    ).thenAnswer((_) async => true);
  });

  // ignore: invalid_use_of_visible_for_testing_member
  tearDown(OTelAPI.reset);

  group('EmbraceOTelFactory', () {
    test('before start(), OTelFactory is null', () {
      expect(OTelFactory.otelFactory, isNull);
    });

    test('after start(), OTelFactory is EmbraceOTelFactory', () async {
      await Embrace.instance.start();

      expect(OTelFactory.otelFactory, isA<EmbraceOTelFactory>());
    });

    test('after start(), OTelAPI.tracerProvider() is non-null', () async {
      await Embrace.instance.start();

      expect(OTelAPI.tracerProvider(), isNotNull);
    });

    test('calling start() twice does not throw', () async {
      await expectLater(
        () async {
          await Embrace.instance.start();
          await Embrace.instance.start();
        },
        returnsNormally,
      );
    });

    test('OTelAPI.reset() leaves OTelFactory in no-op state', () async {
      await Embrace.instance.start();
      expect(OTelFactory.otelFactory, isA<EmbraceOTelFactory>());

      // ignore: invalid_use_of_visible_for_testing_member
      OTelAPI.reset();

      expect(OTelFactory.otelFactory, isNull);
    });
  });
}
