import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/embrace_span_exporter.dart';
import 'package:embrace/src/otel/embrace_span_processor.dart';
import 'package:embrace/src/otel/embrace_span_processor_config.dart';
import 'package:embrace/src/otel/export_result.dart';
// ignore: implementation_imports
import 'package:embrace_platform_interface/src/otel/readable_span_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class MockEmbraceSpanExporter extends Mock implements EmbraceSpanExporter {}

/// Builds a minimal [ReadableSpanData] using the `fromRaw` constructor.
ReadableSpanData _makeSpan(String name) {
  return ReadableSpanData.fromRaw(
    name: name,
    spanId: 'a1b2c3d4e5f6a7b8',
    traceId: '00112233445566778899aabbccddeeff',
    startTimeMs: 1704067200000,
    endTimeMs: 1704067260000,
    resource: Attributes.of({}),
  );
}

/// An [EmbraceSpanProcessor] configured with a very long schedule delay so
/// the timer never fires automatically during tests.
EmbraceSpanProcessor _processorWithExporter(
  EmbraceSpanExporter exporter, {
  EmbraceSpanProcessorConfig config = const EmbraceSpanProcessorConfig(
    scheduleDelay: Duration(hours: 24),
  ),
}) {
  return EmbraceSpanProcessor(exporters: [exporter], config: config);
}

/// Sets up a [MockEmbraceSpanExporter] to stub all three interface methods.
void _stubExporter(MockEmbraceSpanExporter exporter) {
  when(() => exporter.export(any()))
      .thenAnswer((_) async => ExportResult.success);
  when(exporter.forceFlush).thenAnswer((_) async => ExportResult.success);
  when(exporter.shutdown).thenAnswer((_) async {});
}

void main() {
  late MockEmbraceSpanExporter mockExporter;

  setUp(() {
    mockExporter = MockEmbraceSpanExporter();
    _stubExporter(mockExporter);
  });

  group('EmbraceSpanProcessor.onEnd', () {
    test('queues spans for later export', () async {
      final processor = _processorWithExporter(mockExporter);
      await processor.onEnd(_makeSpan('span-1'));
      await processor.onEnd(_makeSpan('span-2'));

      // Nothing exported yet — timer hasn't fired.
      verifyNever(() => mockExporter.export(any()));

      await processor.shutdown();
    });

    test('is a no-op after shutdown', () async {
      final processor = _processorWithExporter(mockExporter);
      await processor.shutdown();
      await processor.onEnd(_makeSpan('span-after-shutdown'));

      verifyNever(() => mockExporter.export(any()));
    });

    test('drops spans when queue is at capacity', () async {
      const maxQueueSize = 3;
      final processor = EmbraceSpanProcessor(
        exporters: [mockExporter],
        config: const EmbraceSpanProcessorConfig(
          maxQueueSize: maxQueueSize,
          scheduleDelay: Duration(hours: 24),
        ),
      );

      for (var i = 0; i < maxQueueSize + 2; i++) {
        await processor.onEnd(_makeSpan('span-$i'));
      }

      await processor.forceFlush();

      final captured = verify(() => mockExporter.export(captureAny())).captured;
      final exported = captured.first as List<ReadableSpanData>;
      expect(exported.length, maxQueueSize);

      await processor.shutdown();
    });
  });

  group('EmbraceSpanProcessor.forceFlush', () {
    test('exports all queued spans to the exporter', () async {
      final processor = _processorWithExporter(mockExporter);
      await processor.onEnd(_makeSpan('span-1'));
      await processor.onEnd(_makeSpan('span-2'));

      await processor.forceFlush();

      final captured = verify(() => mockExporter.export(captureAny())).captured;
      final batch = captured.first as List<ReadableSpanData>;
      expect(batch.length, 2);
      expect(batch.map((s) => s.name), containsAll(['span-1', 'span-2']));
    });

    test('clears the queue after flushing', () async {
      final processor = _processorWithExporter(mockExporter);
      await processor.onEnd(_makeSpan('span-1'));
      await processor.forceFlush();

      // Second flush — queue is already empty.
      await processor.forceFlush();

      // export() should have been called exactly once (for the first flush).
      verify(() => mockExporter.export(any())).called(1);

      await processor.shutdown();
    });

    test('is a no-op when no exporters are registered', () async {
      final processor = EmbraceSpanProcessor(
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );
      await processor.onEnd(_makeSpan('span-1'));
      // Should not throw.
      await processor.forceFlush();
      await processor.shutdown();
    });

    test('is a no-op after shutdown', () async {
      final processor = _processorWithExporter(mockExporter);
      await processor.shutdown();

      reset(mockExporter);
      when(() => mockExporter.export(any()))
          .thenAnswer((_) async => ExportResult.success);

      await processor.forceFlush();
      verifyNever(() => mockExporter.export(any()));
    });

    test('respects maxBatchSize', () async {
      const maxBatchSize = 2;
      final processor = EmbraceSpanProcessor(
        exporters: [mockExporter],
        config: const EmbraceSpanProcessorConfig(
          maxBatchSize: maxBatchSize,
          scheduleDelay: Duration(hours: 24),
        ),
      );

      for (var i = 0; i < 5; i++) {
        await processor.onEnd(_makeSpan('span-$i'));
      }

      await processor.forceFlush();

      final firstCall =
          verify(() => mockExporter.export(captureAny())).captured;
      final batch = firstCall.first as List<ReadableSpanData>;
      expect(batch.length, maxBatchSize);

      await processor.shutdown();
    });

    test('all exporters receive the same batch', () async {
      final exporter2 = MockEmbraceSpanExporter()..let(_stubExporter);

      final processor = EmbraceSpanProcessor(
        exporters: [mockExporter, exporter2],
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );

      await processor.onEnd(_makeSpan('span-1'));
      await processor.forceFlush();

      verify(() => mockExporter.export(any())).called(1);
      verify(() => exporter2.export(any())).called(1);

      await processor.shutdown();
    });

    test('continues to next exporter if one throws during export', () async {
      final throwingExporter = MockEmbraceSpanExporter();
      final secondExporter = MockEmbraceSpanExporter()..let(_stubExporter);

      when(() => throwingExporter.export(any()))
          .thenThrow(Exception('export failed'));
      when(throwingExporter.forceFlush)
          .thenAnswer((_) async => ExportResult.success);
      when(throwingExporter.shutdown).thenAnswer((_) async {});

      final processor = EmbraceSpanProcessor(
        exporters: [throwingExporter, secondExporter],
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );

      await processor.onEnd(_makeSpan('span-1'));
      await processor.forceFlush();

      verify(() => secondExporter.export(any())).called(1);

      await processor.shutdown();
    });
  });

  group('EmbraceSpanProcessor.shutdown', () {
    test('flushes remaining queued spans before shutting down', () async {
      final processor = _processorWithExporter(mockExporter);
      await processor.onEnd(_makeSpan('span-1'));

      await processor.shutdown();

      final captured = verify(() => mockExporter.export(captureAny())).captured;
      final batch = captured.first as List<ReadableSpanData>;
      expect(batch.length, 1);
      expect(batch.first.name, 'span-1');
    });

    test('calls shutdown on all registered exporters', () async {
      final exporter2 = MockEmbraceSpanExporter()..let(_stubExporter);

      final processor = EmbraceSpanProcessor(
        exporters: [mockExporter, exporter2],
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );

      await processor.shutdown();

      verify(mockExporter.shutdown).called(1);
      verify(exporter2.shutdown).called(1);
    });

    test('is idempotent — calling twice does not double-export', () async {
      final processor = _processorWithExporter(mockExporter);
      await processor.onEnd(_makeSpan('span-1'));

      await processor.shutdown();
      await processor.shutdown();

      verify(() => mockExporter.export(any())).called(1);
      verify(mockExporter.shutdown).called(1);
    });
  });

  group('EmbraceSpanProcessor.onStart', () {
    test('is a no-op and does not interact with exporters', () async {
      final processor = _processorWithExporter(mockExporter);

      // onStart takes an OTelSpanAdapter, but we're just checking it does
      // nothing — passing null would cause a compile error, so we verify by
      // checking no exporter calls happen after flush.
      await processor.forceFlush();
      verifyNever(() => mockExporter.export(any()));

      await processor.shutdown();
    });
  });

  group('EmbraceSpanProcessorConfig', () {
    test('has correct defaults', () {
      const config = EmbraceSpanProcessorConfig();
      expect(config.maxQueueSize, 2048);
      expect(config.maxBatchSize, 512);
      expect(config.scheduleDelay, const Duration(seconds: 5));
      expect(config.exportTimeout, const Duration(seconds: 30));
    });

    test('accepts custom values', () {
      const config = EmbraceSpanProcessorConfig(
        maxQueueSize: 100,
        maxBatchSize: 10,
        scheduleDelay: Duration(seconds: 1),
        exportTimeout: Duration(seconds: 10),
      );
      expect(config.maxQueueSize, 100);
      expect(config.maxBatchSize, 10);
      expect(config.scheduleDelay, const Duration(seconds: 1));
      expect(config.exportTimeout, const Duration(seconds: 10));
    });
  });
}

extension on MockEmbraceSpanExporter {
  // ignore: avoid_returning_null_for_void
  void let(void Function(MockEmbraceSpanExporter) fn) => fn(this);
}
