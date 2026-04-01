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

    group('addSpanExporter', () {
      const endpoint = 'https://collector.example.com/v1/traces';

      test('forwards to platform immediately when already started', () {
        when(() => platform.isStarted).thenReturn(true);
        when(
          () => platform.addSpanExporter(
            endpoint: any(named: 'endpoint'),
            headers: any(named: 'headers'),
            timeoutSeconds: any(named: 'timeoutSeconds'),
          ),
        ).thenReturn(null);

        provider.addSpanExporter(endpoint: endpoint);

        verify(
          () => platform.addSpanExporter(
            endpoint: endpoint,
            headers: null,
            timeoutSeconds: null,
          ),
        ).called(1);
      });
    });
  });

  group('EmbraceTracerProvider pre-start queueing', () {
    test('queues exporter and flushes it when SDK starts', () async {
      when(
        () => platform.addSpanExporter(
          endpoint: any(named: 'endpoint'),
          headers: any(named: 'headers'),
          timeoutSeconds: any(named: 'timeoutSeconds'),
        ),
      ).thenReturn(null);

      // Call before start — platform is not yet started
      when(() => platform.isStarted).thenReturn(false);
      final provider = EmbraceTracerProvider(endpoint: '');
      provider.addSpanExporter(
        endpoint: 'https://collector.example.com/v1/traces',
        headers: [
          {'Authorization': 'Bearer tok'},
        ],
        timeoutSeconds: 30,
      );

      // Platform not called yet
      verifyNever(
        () => platform.addSpanExporter(
          endpoint: any(named: 'endpoint'),
          headers: any(named: 'headers'),
          timeoutSeconds: any(named: 'timeoutSeconds'),
        ),
      );

      // Flush — simulates what _start() does
      provider.flushPendingExporters();

      verify(
        () => platform.addSpanExporter(
          endpoint: 'https://collector.example.com/v1/traces',
          headers: [
            {'Authorization': 'Bearer tok'},
          ],
          timeoutSeconds: 30,
        ),
      ).called(1);
    });

    test('resetForTesting() clears pending queue', () {
      when(() => platform.isStarted).thenReturn(false);
      final provider = EmbraceTracerProvider(endpoint: '');
      provider.addSpanExporter(endpoint: 'https://collector.example.com');

      // ignore: invalid_use_of_visible_for_testing_member
      provider.resetForTesting();
      provider.flushPendingExporters();

      verifyNever(
        () => platform.addSpanExporter(
          endpoint: any(named: 'endpoint'),
          headers: any(named: 'headers'),
          timeoutSeconds: any(named: 'timeoutSeconds'),
        ),
      );
    });
  });
}
