import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/embrace.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/tracing/embrace_tracer.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/tracing/embrace_tracer_provider.dart';
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

  group('EmbraceTracerProvider', () {
    late EmbraceTracerProvider provider;

    setUp(() async {
      await Embrace.instance.start();
      provider = OTelAPI.tracerProvider() as EmbraceTracerProvider;
    });

    test('OTelAPI.tracerProvider() returns an EmbraceTracerProvider', () {
      expect(provider, isA<EmbraceTracerProvider>());
    });

    test('getTracer() returns an EmbraceTracer', () {
      expect(provider.getTracer('x'), isA<EmbraceTracer>());
    });

    test('repeated getTracer() calls return the same instance', () {
      final first = provider.getTracer('x');
      final second = provider.getTracer('y');

      expect(identical(first, second), isTrue);
    });

    test('shutdown() sets isShutdown to true', () async {
      expect(provider.isShutdown, isFalse);

      await provider.shutdown();

      expect(provider.isShutdown, isTrue);
    });

    test('shutdown() sets enabled to false', () async {
      expect(provider.enabled, isTrue);

      await provider.shutdown();

      expect(provider.enabled, isFalse);
    });
  });
}
