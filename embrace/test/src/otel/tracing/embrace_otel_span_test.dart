import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart'
    as otel;
import 'package:embrace/embrace.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/tracing/embrace_otel_span.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

const _spanId = 'native-span-id';

/// Stubs `platform.startSpan` to return [_spanId].
void _stubStartSpan(MockEmbracePlatform platform) {
  when(
    () => platform.startSpan(
      any(),
      parentSpanId: any(named: 'parentSpanId'),
      startTimeMs: any(named: 'startTimeMs'),
    ),
  ).thenAnswer((_) async => _spanId);
}

/// Stubs all platform span-mutation methods to return `true`.
void _stubSpanMutations(MockEmbracePlatform platform) {
  when(
    () => platform.addSpanAttribute(any(), any(), any()),
  ).thenAnswer((_) async => true);

  when(
    () => platform.addSpanEvent(
      any(),
      any(),
      timestampMs: any(named: 'timestampMs'),
      attributes: any(named: 'attributes'),
    ),
  ).thenAnswer((_) async => true);

  when(
    () => platform.stopSpan(any(), endTimeMs: any(named: 'endTimeMs')),
  ).thenAnswer((_) async => true);

  when(
    () => platform.setSpanStatus(
      any(),
      any(),
      description: any(named: 'description'),
    ),
  ).thenAnswer((_) async => true);

  when(
    () => platform.updateSpanName(any(), any()),
  ).thenAnswer((_) async => true);

  when(
    () => platform.addSpanLink(any(), any(), any(), any()),
  ).thenAnswer((_) async => true);
}

/// Creates a ready-to-use [EmbraceOTelSpan] backed by [platform].
///
/// The underlying `OTelFactory` must be initialised (via
/// `Embrace.instance.start`) before calling this helper.
EmbraceOTelSpan _makeSpan(MockEmbracePlatform platform) {
  final sc = otel.OTelFactory.otelFactory!.spanContext(
    traceId: otel.OTelFactory.otelFactory!.traceId(),
    spanId: otel.OTelFactory.otelFactory!.spanId(),
    parentSpanId: otel.OTelFactory.otelFactory!.spanIdInvalid(),
  );
  final scope = otel.InstrumentationScopeCreate.create(name: 'test');
  return EmbraceOTelSpan(
    name: 'test-span',
    nativeSpanId: platform.startSpan('test-span'),
    spanContext: sc,
    instrumentationScope: scope,
  );
}

/// Pumps the microtask queue so that async `_withSpanId` closures complete.
Future<void> _pump() => Future.microtask(() {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(SpanStatusCode.unset);
  });

  late MockEmbracePlatform platform;
  late EmbraceOTelSpan span;

  setUp(() async {
    platform = MockEmbracePlatform();
    EmbracePlatform.instance = platform;
    when(
      () => platform.attachToHostSdk(
        enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
      ),
    ).thenAnswer((_) async => true);

    await Embrace.instance.start();
    _stubStartSpan(platform);
    _stubSpanMutations(platform);
    span = _makeSpan(platform);
  });

  // ignore: invalid_use_of_visible_for_testing_member
  tearDown(otel.OTelAPI.reset);

  group('EmbraceOTelSpan', () {
    group('attribute setters', () {
      test('setStringAttribute calls addSpanAttribute', () async {
        span.setStringAttribute<String>('key', 'value');
        await _pump();
        verify(
          () => platform.addSpanAttribute(_spanId, 'key', 'value'),
        ).called(1);
      });

      test('setBoolAttribute serialises to string', () async {
        span.setBoolAttribute('flag', true);
        await _pump();
        verify(
          () => platform.addSpanAttribute(_spanId, 'flag', 'true'),
        ).called(1);
      });

      test('setIntAttribute serialises to string', () async {
        span.setIntAttribute('count', 42);
        await _pump();
        verify(
          () => platform.addSpanAttribute(_spanId, 'count', '42'),
        ).called(1);
      });

      test('setDoubleAttribute serialises to string', () async {
        span.setDoubleAttribute('ratio', 3.14);
        await _pump();
        verify(
          () => platform.addSpanAttribute(_spanId, 'ratio', '3.14'),
        ).called(1);
      });

      test('attribute setters are no-ops after end', () async {
        span
          ..end()
          ..setStringAttribute<String>('key', 'value');
        await _pump();
        verifyNever(
          () => platform.addSpanAttribute(any(), any(), any()),
        );
      });
    });

    group('addEventNow', () {
      test('calls addSpanEvent with correct spanId and name', () async {
        span.addEventNow('my-event');
        await _pump();
        verify(
          () => platform.addSpanEvent(
            _spanId,
            'my-event',
            timestampMs: any(named: 'timestampMs'),
            attributes: any(named: 'attributes'),
          ),
        ).called(1);
      });

      test('serialises attributes to Map<String, String>', () async {
        final attrs = otel.Attributes.of({'k': 'v'});
        span.addEventNow('ev', attrs);
        await _pump();
        verify(
          () => platform.addSpanEvent(
            _spanId,
            'ev',
            timestampMs: any(named: 'timestampMs'),
            attributes: {'k': 'v'},
          ),
        ).called(1);
      });
    });

    group('end', () {
      test('calls stopSpan and sets isRecording to false', () async {
        expect(span.isRecording, isTrue);
        span.end();
        await _pump();
        expect(span.isRecording, isFalse);
        verify(
          () => platform.stopSpan(_spanId, endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      test('calling end twice calls stopSpan exactly once', () async {
        span
          ..end()
          ..end();
        await _pump();
        verify(
          () => platform.stopSpan(_spanId, endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });
    });

    group('setStatus', () {
      test('SpanStatusCode.Error calls setSpanStatus with error status',
          () async {
        span.setStatus(otel.SpanStatusCode.Error);
        await _pump();
        verify(
          () => platform.setSpanStatus(
            _spanId,
            SpanStatusCode.error,
            description: any(named: 'description'),
          ),
        ).called(1);
      });

      test('SpanStatusCode.Ok calls setSpanStatus with ok status', () async {
        span.setStatus(otel.SpanStatusCode.Ok);
        await _pump();
        verify(
          () => platform.setSpanStatus(
            _spanId,
            SpanStatusCode.ok,
            description: any(named: 'description'),
          ),
        ).called(1);
      });

      test('SpanStatusCode.Unset is ignored', () async {
        span.setStatus(otel.SpanStatusCode.Unset);
        await _pump();
        verifyNever(
          () => platform.setSpanStatus(any(), any()),
        );
      });

      test('Error does not downgrade Ok — platform not called', () async {
        span
          ..setStatus(otel.SpanStatusCode.Ok)
          ..setStatus(otel.SpanStatusCode.Error);
        await _pump();
        verify(
          () => platform.setSpanStatus(
            _spanId,
            SpanStatusCode.ok,
            description: any(named: 'description'),
          ),
        ).called(1);
        verifyNever(
          () => platform.setSpanStatus(
            any(),
            SpanStatusCode.error,
            description: any(named: 'description'),
          ),
        );
      });
    });

    group('recordException', () {
      test('adds an exception event with standard OTel attributes', () async {
        final exception = StateError('boom');
        span.recordException(exception);
        await _pump();

        final captured = verify(
          () => platform.addSpanEvent(
            _spanId,
            'exception',
            timestampMs: any(named: 'timestampMs'),
            attributes: captureAny(named: 'attributes'),
          ),
        ).captured;

        final attrs = captured.single as Map<String, String>;
        expect(attrs['exception.type'], 'StateError');
        expect(attrs, contains('exception.message'));
      });

      test('includes stacktrace when provided', () async {
        final st = StackTrace.current;
        span.recordException(Exception('boom'), stackTrace: st);
        await _pump();

        final captured = verify(
          () => platform.addSpanEvent(
            _spanId,
            'exception',
            timestampMs: any(named: 'timestampMs'),
            attributes: captureAny(named: 'attributes'),
          ),
        ).captured;

        final attrs = captured.single as Map<String, String>;
        expect(attrs, contains('exception.stacktrace'));
      });
    });

    group('addLink', () {
      test('calls addSpanLink with linked traceId and spanId', () async {
        final linkedTraceId = otel.OTelFactory.otelFactory!.traceId();
        final linkedSpanId = otel.OTelFactory.otelFactory!.spanId();
        final linkedContext = otel.OTelFactory.otelFactory!.spanContext(
          traceId: linkedTraceId,
          spanId: linkedSpanId,
          parentSpanId: otel.OTelFactory.otelFactory!.spanIdInvalid(),
        );
        span.addLink(linkedContext);
        await _pump();
        verify(
          () => platform.addSpanLink(
            _spanId,
            linkedTraceId.toString(),
            linkedSpanId.toString(),
            any(),
          ),
        ).called(1);
      });

      test('serialises link attributes to Map<String, String>', () async {
        final linkedTraceId = otel.OTelFactory.otelFactory!.traceId();
        final linkedSpanId = otel.OTelFactory.otelFactory!.spanId();
        final linkedContext = otel.OTelFactory.otelFactory!.spanContext(
          traceId: linkedTraceId,
          spanId: linkedSpanId,
          parentSpanId: otel.OTelFactory.otelFactory!.spanIdInvalid(),
        );
        final attrs = otel.Attributes.of({'link-key': 'link-val'});
        span.addLink(linkedContext, attrs);
        await _pump();
        verify(
          () => platform.addSpanLink(
            _spanId,
            any(),
            any(),
            {'link-key': 'link-val'},
          ),
        ).called(1);
      });
    });

    group('empty collections', () {
      test('spanEvents returns empty list', () {
        expect(span.spanEvents, isEmpty);
      });

      test('spanLinks returns empty list', () {
        expect(span.spanLinks, isEmpty);
      });

      test('attributes returns empty Attributes', () {
        // ignore: invalid_use_of_visible_for_testing_member
        expect(span.attributes.isEmpty, isTrue);
      });
    });
  });
}
