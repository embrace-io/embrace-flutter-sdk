import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:embrace/src/otel/embrace_span_processor.dart';
import 'package:embrace/src/otel/embrace_span_processor_config.dart';
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

  const parentSpanId = 'a1b2c3d4e5f6a7b8';
  const childSpanId = 'b2c3d4e5f6a7b8c9';
  const traceId = 'abcdef1234567890abcdef1234567890';

  void stubStartSpan(String returnId) {
    when(
      () => platform.startSpan(
        any(),
        parentSpanId: any(named: 'parentSpanId'),
        startTimeMs: any(named: 'startTimeMs'),
      ),
    ).thenAnswer((_) async => returnId);
  }

  void stubStopSpan() {
    when(
      () => platform.stopSpan(
        any(),
        errorCode: any(named: 'errorCode'),
        endTimeMs: any(named: 'endTimeMs'),
      ),
    ).thenAnswer((_) async => true);
  }

  void stubGetTraceId() {
    when(() => platform.getTraceId(any())).thenAnswer((_) async => traceId);
  }

  setUp(() {
    platform = MockEmbracePlatform();
    EmbracePlatform.instance = platform;
    // Reset OTel context between tests.
    Context.resetCurrent();
  });

  tearDown(() async {
    await Embrace.instance.resetForTesting();
    Context.resetCurrent();
  });

  group('Context tracking in startSpan', () {
    setUp(() {
      // Wire up a processor so EmbraceSpanImpl has a working processor
      // (needed for _notifyProcessorOnEnd not to throw).
      Embrace.instance.spanProcessorForTesting = EmbraceSpanProcessor(
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );
    });

    test('OTelContextUtils.currentSpan is set after startSpan', () async {
      stubStartSpan(parentSpanId);
      stubGetTraceId();

      expect(Embrace.instance.contextUtilsForTesting.currentSpan(), isNull);

      await Embrace.instance.startSpan('parent-span');

      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan(),
        isNotNull,
      );
      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan()!.embraceSpan.id,
        equals(parentSpanId),
      );
    });

    test('Context is restored to null after stop() when no parent', () async {
      stubStartSpan(parentSpanId);
      stubStopSpan();
      stubGetTraceId();

      final span = await Embrace.instance.startSpan('parent-span');
      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan(),
        isNotNull,
      );

      await span!.stop();

      expect(Embrace.instance.contextUtilsForTesting.currentSpan(), isNull);
    });

    test('Calling stop() twice does not corrupt the context stack', () async {
      stubStartSpan(parentSpanId);
      stubStopSpan();
      stubGetTraceId();

      final span = await Embrace.instance.startSpan('parent-span');
      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan(),
        isNotNull,
      );

      await span!.stop();
      expect(Embrace.instance.contextUtilsForTesting.currentSpan(), isNull);

      // Second stop() must not corrupt the (now-empty) context.
      await span.stop();
      expect(Embrace.instance.contextUtilsForTesting.currentSpan(), isNull);
    });

    test('Context restores parent span after child stops', () async {
      // First startSpan call returns parentSpanId, second returns childSpanId.
      var callCount = 0;
      when(
        () => platform.startSpan(
          any(),
          parentSpanId: any(named: 'parentSpanId'),
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? parentSpanId : childSpanId;
      });
      stubStopSpan();
      when(() => platform.getTraceId(any())).thenAnswer((_) async => traceId);

      final parent = await Embrace.instance.startSpan('parent-span');
      final parentAdapter =
          Embrace.instance.contextUtilsForTesting.currentSpan();
      expect(parentAdapter, isNotNull);

      final child = await Embrace.instance.startSpan('child-span');
      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan()!.embraceSpan.id,
        equals(childSpanId),
      );

      await child!.stop();

      // Context should be restored to the parent adapter.
      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan(),
        same(parentAdapter),
      );

      await parent!.stop();
      expect(Embrace.instance.contextUtilsForTesting.currentSpan(), isNull);
    });

    test('child startSpan uses Context parent when explicit parent is null',
        () async {
      var callCount = 0;
      when(
        () => platform.startSpan(
          any(),
          parentSpanId: any(named: 'parentSpanId'),
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? parentSpanId : childSpanId;
      });
      when(() => platform.getTraceId(any())).thenAnswer((_) async => traceId);

      await Embrace.instance.startSpan('parent-span');

      // Start child without explicit parent — should use Context.
      await Embrace.instance.startSpan('child-span');

      // Verify child was started with the parent span ID from Context.
      verify(
        () => platform.startSpan(
          'child-span',
          parentSpanId: parentSpanId,
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).called(1);
    });

    test('explicit parent takes precedence over Context current span',
        () async {
      const explicitParentId = 'c3d4e5f6a7b8c9d0';
      var callCount = 0;
      when(
        () => platform.startSpan(
          any(),
          parentSpanId: any(named: 'parentSpanId'),
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? parentSpanId : childSpanId;
      });
      when(() => platform.getTraceId(any())).thenAnswer((_) async => traceId);

      // Put a span in context.
      await Embrace.instance.startSpan('context-span');

      // Create an explicit parent span mock.
      final explicitParent = _FakeEmbraceSpan(explicitParentId);

      // Start child with explicit parent — should NOT use Context parent.
      await Embrace.instance.startSpan(
        'child-span',
        parent: explicitParent,
      );

      // Verify child was started with the explicit parent ID, not the
      // context parent.
      verify(
        () => platform.startSpan(
          'child-span',
          parentSpanId: explicitParentId,
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).called(1);
    });

    test('current span is accessible after an async gap', () async {
      stubStartSpan(parentSpanId);
      when(() => platform.getTraceId(any())).thenAnswer((_) async => traceId);

      await Embrace.instance.startSpan('span');

      // Simulate an async gap.
      await Future<void>.delayed(Duration.zero);

      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan(),
        isNotNull,
      );
      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan()!.embraceSpan.id,
        equals(parentSpanId),
      );
    });
  });

  group('generateW3cTraceparent with OTel Context', () {
    setUp(() {
      Embrace.instance.spanProcessorForTesting = EmbraceSpanProcessor(
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );
    });

    test('returns traceparent from Dart-side Context when current span exists',
        () async {
      stubStartSpan(parentSpanId);
      stubGetTraceId();

      await Embrace.instance.startSpan('parent-span');

      final result = await Embrace.instance.generateW3cTraceparent(null, null);

      expect(result, isNotNull);
      // W3C traceparent format: 00-{traceId}-{spanId}-{flags}
      expect(result, startsWith('00-'));
      expect(result, contains(traceId));
      expect(result, contains(parentSpanId));
      // Native method should NOT have been called.
      verifyNever(
        () => platform.generateW3cTraceparent(any(), any()),
      );
    });

    test('falls back to native when no Dart-side span exists in Context',
        () async {
      const nativeTraceparent =
          '00-11223344556677889900aabbccddeeff-aabbccddeeff0011-01';
      when(
        () => platform.generateW3cTraceparent(any(), any()),
      ).thenAnswer((_) async => nativeTraceparent);

      expect(
        Embrace.instance.contextUtilsForTesting.currentSpan(),
        isNull,
      );

      final result = await Embrace.instance.generateW3cTraceparent(null, null);

      expect(result, equals(nativeTraceparent));
      verify(
        () => platform.generateW3cTraceparent(null, null),
      ).called(1);
    });

    test('falls back to native after all spans have been stopped', () async {
      stubStartSpan(parentSpanId);
      stubStopSpan();
      stubGetTraceId();

      const nativeTraceparent =
          '00-11223344556677889900aabbccddeeff-aabbccddeeff0011-01';
      when(
        () => platform.generateW3cTraceparent(any(), any()),
      ).thenAnswer((_) async => nativeTraceparent);

      final span = await Embrace.instance.startSpan('parent-span');
      await span!.stop();

      expect(Embrace.instance.contextUtilsForTesting.currentSpan(), isNull);

      final result = await Embrace.instance.generateW3cTraceparent(null, null);

      expect(result, equals(nativeTraceparent));
      verify(
        () => platform.generateW3cTraceparent(null, null),
      ).called(1);
    });
  });
}

/// A minimal [EmbraceSpan] stub for use as an explicit parent in tests.
class _FakeEmbraceSpan extends EmbraceSpan {
  _FakeEmbraceSpan(super.id);

  @override
  Future<String> get traceId async => '0' * 32;

  @override
  Future<bool> stop({ErrorCode? errorCode, int? endTimeMs}) async => false;

  @override
  Future<bool> addEvent(
    String name, {
    int? timestampMs,
    Map<String, String>? attributes,
  }) async =>
      false;

  @override
  Future<bool> addAttribute(String key, String value) async => false;
}
