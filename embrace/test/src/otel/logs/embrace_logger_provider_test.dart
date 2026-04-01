import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/logs/embrace_logger_provider.dart';
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
  });

  // ignore: invalid_use_of_visible_for_testing_member
  tearDown(OTelAPI.reset);

  group('EmbraceLoggerProvider', () {
    late EmbraceLoggerProvider provider;

    setUp(() {
      provider = EmbraceLoggerProvider(endpoint: '');
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

    test('getLogger() returns an APILogger', () {
      expect(provider.getLogger('test'), isA<APILogger>());
    });

    group('addLogRecordExporter', () {
      const endpoint = 'https://collector.example.com/v1/logs';

      test('forwards to platform immediately when already started', () {
        when(() => platform.isStarted).thenReturn(true);
        when(
          () => platform.addLogRecordExporter(
            endpoint: any(named: 'endpoint'),
            headers: any(named: 'headers'),
            timeoutSeconds: any(named: 'timeoutSeconds'),
          ),
        ).thenReturn(null);

        provider.addLogRecordExporter(endpoint: endpoint);

        verify(
          () => platform.addLogRecordExporter(
            endpoint: endpoint,
            headers: null,
            timeoutSeconds: null,
          ),
        ).called(1);
      });

      test('queues exporter when SDK not yet started', () {
        when(() => platform.isStarted).thenReturn(false);
        when(
          () => platform.addLogRecordExporter(
            endpoint: any(named: 'endpoint'),
            headers: any(named: 'headers'),
            timeoutSeconds: any(named: 'timeoutSeconds'),
          ),
        ).thenReturn(null);

        provider.addLogRecordExporter(endpoint: endpoint);

        verifyNever(
          () => platform.addLogRecordExporter(
            endpoint: any(named: 'endpoint'),
            headers: any(named: 'headers'),
            timeoutSeconds: any(named: 'timeoutSeconds'),
          ),
        );
      });
    });

    group('flushPendingExporters', () {
      const endpoint = 'https://collector.example.com/v1/logs';

      test('forwards queued exporters to platform', () {
        when(() => platform.isStarted).thenReturn(false);
        when(
          () => platform.addLogRecordExporter(
            endpoint: any(named: 'endpoint'),
            headers: any(named: 'headers'),
            timeoutSeconds: any(named: 'timeoutSeconds'),
          ),
        ).thenReturn(null);

        provider
          ..addLogRecordExporter(
            endpoint: endpoint,
            headers: [
              {'X-Api-Key': 'secret'},
            ],
            timeoutSeconds: 15,
          )
          ..flushPendingExporters();

        verify(
          () => platform.addLogRecordExporter(
            endpoint: endpoint,
            headers: [
              {'X-Api-Key': 'secret'},
            ],
            timeoutSeconds: 15,
          ),
        ).called(1);
      });

      test('clears queue after flush so second flush is a no-op', () {
        when(() => platform.isStarted).thenReturn(false);
        when(
          () => platform.addLogRecordExporter(
            endpoint: any(named: 'endpoint'),
            headers: any(named: 'headers'),
            timeoutSeconds: any(named: 'timeoutSeconds'),
          ),
        ).thenReturn(null);

        provider
          ..addLogRecordExporter(endpoint: endpoint)
          ..flushPendingExporters()
          ..flushPendingExporters();

        verify(
          () => platform.addLogRecordExporter(
            endpoint: any(named: 'endpoint'),
            headers: any(named: 'headers'),
            timeoutSeconds: any(named: 'timeoutSeconds'),
          ),
        ).called(1);
      });
    });

    test('flushes multiple queued exporters in order', () {
      when(() => platform.isStarted).thenReturn(false);

      final callOrder = <String>[];
      when(
        () => platform.addLogRecordExporter(
          endpoint: 'https://first.example.com',
          headers: any(named: 'headers'),
          timeoutSeconds: any(named: 'timeoutSeconds'),
        ),
      ).thenAnswer((_) => callOrder.add('first'));
      when(
        () => platform.addLogRecordExporter(
          endpoint: 'https://second.example.com',
          headers: any(named: 'headers'),
          timeoutSeconds: any(named: 'timeoutSeconds'),
        ),
      ).thenAnswer((_) => callOrder.add('second'));

      provider
        ..addLogRecordExporter(endpoint: 'https://first.example.com')
        ..addLogRecordExporter(endpoint: 'https://second.example.com')
        ..flushPendingExporters();

      expect(callOrder, ['first', 'second']);
    });

    test('resetForTesting() clears pending queue', () {
      when(() => platform.isStarted).thenReturn(false);
      when(
        () => platform.addLogRecordExporter(
          endpoint: any(named: 'endpoint'),
          headers: any(named: 'headers'),
          timeoutSeconds: any(named: 'timeoutSeconds'),
        ),
      ).thenReturn(null);

      // ignore: invalid_use_of_visible_for_testing_member
      provider
        ..addLogRecordExporter(
          endpoint: 'https://collector.example.com/v1/logs',
        )
        ..resetForTesting()
        ..flushPendingExporters();

      verifyNever(
        () => platform.addLogRecordExporter(
          endpoint: any(named: 'endpoint'),
          headers: any(named: 'headers'),
          timeoutSeconds: any(named: 'timeoutSeconds'),
        ),
      );
    });
  });
}
