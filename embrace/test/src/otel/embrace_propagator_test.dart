import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart'
    show OTel, W3CTraceContextPropagator;
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/embrace.dart';
import 'package:embrace/src/otel/embrace_span_processor.dart';
import 'package:embrace/src/otel/embrace_span_processor_config.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'otel_test_fixtures.dart';

class _MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

/// Writes into a [Map<String, String>] carrier.
class _MapSetter implements TextMapSetter<String> {
  _MapSetter(this._map);

  final Map<String, String> _map;

  @override
  void set(String key, String value) => _map[key] = value;
}

/// Reads from a [Map<String, String>] carrier.
class _MapGetter implements TextMapGetter<String> {
  _MapGetter(this._map);

  final Map<String, String> _map;

  @override
  String? get(String key) => _map[key];

  @override
  Iterable<String> keys() => _map.keys;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize the OTel SDK factory once so W3CTraceContextPropagator.extract()
  // can construct SpanContext objects. The 'inject()' direction works without
  // this (it reads context.spanContext directly), but 'extract()' uses
  // OTel.spanContext() internally which requires the SDK factory.
  setUpAll(() async {
    await OTel.initialize(
      serviceName: 'test-embrace-sdk',
      endpoint: 'http://localhost:4317',
    );
  });

  tearDownAll(() async {
    await OTel.reset();
  });

  late _MockEmbracePlatform platform;

  setUp(() {
    platform = _MockEmbracePlatform();
    EmbracePlatform.instance = platform;
    Context.resetCurrent();
  });

  tearDown(() async {
    await Embrace.instance.resetForTesting();
    Context.resetCurrent();
  });

  group('inject()', () {
    setUp(() {
      Embrace.instance.spanProcessorForTesting = EmbraceSpanProcessor(
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );
      when(
        () => platform.startSpan(
          any(),
          parentSpanId: any(named: 'parentSpanId'),
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) async => kTestSpanId);
      when(
        () => platform.getTraceId(any()),
      ).thenAnswer((_) async => kTestTraceId);
    });

    test(
        'Context.current.spanContext is populated after startSpan '
        'so propagator can inject without extra bridging', () async {
      expect(Context.current.spanContext, isNull);

      await Embrace.instance.startSpan('my-span');

      expect(Context.current.spanContext, isNotNull);
      expect(
        Context.current.spanContext!.traceId.hexString,
        equals(kTestTraceId),
      );
      expect(
        Context.current.spanContext!.spanId.hexString,
        equals(kTestSpanId),
      );
    });

    test('sets traceparent header when current span exists', () async {
      await Embrace.instance.startSpan('parent-span');

      final propagator = W3CTraceContextPropagator();
      final headers = <String, String>{};
      propagator.inject(Context.current, headers, _MapSetter(headers));

      expect(headers['traceparent'], isNotNull);
      expect(headers['traceparent'], startsWith('00-'));
      expect(headers['traceparent'], contains(kTestTraceId));
      expect(headers['traceparent'], contains(kTestSpanId));
    });

    test('does not set traceparent header when no current span', () {
      final propagator = W3CTraceContextPropagator();
      // `headers` serves as both the carrier map and the setter target —
      // _MapSetter writes into the same map that is later inspected.
      final headers = <String, String>{};
      propagator.inject(Context.current, headers, _MapSetter(headers));

      expect(headers.containsKey('traceparent'), isFalse);
    });

    test('Context.current.spanContext is cleared after span stops', () async {
      when(
        () => platform.stopSpan(
          any(),
          errorCode: any(named: 'errorCode'),
          endTimeMs: any(named: 'endTimeMs'),
        ),
      ).thenAnswer((_) async => true);

      final span = await Embrace.instance.startSpan('my-span');
      expect(Context.current.spanContext, isNotNull);

      await span!.stop();

      expect(Context.current.spanContext, isNull);
    });

    test('nested spans: stop inner span restores outer span context', () async {
      var startCallCount = 0;
      when(
        () => platform.startSpan(
          any(),
          parentSpanId: any(named: 'parentSpanId'),
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) async {
        startCallCount++;
        return startCallCount == 1 ? kTestSpanId : kTestChildSpanId;
      });
      when(
        () => platform.stopSpan(
          any(),
          errorCode: any(named: 'errorCode'),
          endTimeMs: any(named: 'endTimeMs'),
        ),
      ).thenAnswer((_) async => true);

      final spanA = await Embrace.instance.startSpan('span-a');
      expect(
        Context.current.spanContext!.spanId.hexString,
        equals(kTestSpanId),
      );

      final spanB = await Embrace.instance.startSpan('span-b');
      expect(
        Context.current.spanContext!.spanId.hexString,
        equals(kTestChildSpanId),
      );

      // Stopping the inner span must revert context to the outer span.
      await spanB!.stop();
      expect(
        Context.current.spanContext!.spanId.hexString,
        equals(kTestSpanId),
      );

      // Stopping the outer span must clear the context entirely.
      await spanA!.stop();
      expect(Context.current.spanContext, isNull);
    });

    test('full start() → startSpan() → inject() path produces traceparent',
        () async {
      when(
        () => platform.attachToHostSdk(
          enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
        ),
      ).thenAnswer((_) async => true);

      await Embrace.instance.start();
      await Embrace.instance.startSpan('my-span');

      final propagator = W3CTraceContextPropagator();
      final headers = <String, String>{};
      propagator.inject(Context.current, headers, _MapSetter(headers));

      expect(headers['traceparent'], isNotNull);
      expect(headers['traceparent'], contains(kTestTraceId));
      expect(headers['traceparent'], contains(kTestSpanId));
    });
  });

  group('extract()', () {
    test('returns context with SpanContext from valid traceparent', () {
      const traceparent = '00-$kTestTraceId-$kTestSpanId-01';
      final headers = {'traceparent': traceparent};

      final propagator = W3CTraceContextPropagator();
      final extracted =
          propagator.extract(Context.current, headers, _MapGetter(headers));

      expect(extracted.spanContext, isNotNull);
      expect(extracted.spanContext!.traceId.hexString, equals(kTestTraceId));
      expect(extracted.spanContext!.spanId.hexString, equals(kTestSpanId));
      expect(extracted.spanContext!.isRemote, isTrue);
    });

    test('returns context unchanged when traceparent header is absent', () {
      final propagator = W3CTraceContextPropagator();
      final extracted = propagator.extract(
        Context.current,
        <String, String>{},
        _MapGetter(<String, String>{}),
      );

      expect(extracted.spanContext, isNull);
    });

    test('returns context unchanged for malformed traceparent', () {
      final headers = {'traceparent': 'not-a-valid-traceparent'};
      final propagator = W3CTraceContextPropagator();
      final extracted =
          propagator.extract(Context.current, headers, _MapGetter(headers));

      expect(extracted.spanContext, isNull);
    });
  });

  group('inject/extract round-trip', () {
    setUp(() {
      Embrace.instance.spanProcessorForTesting = EmbraceSpanProcessor(
        config: const EmbraceSpanProcessorConfig(
          scheduleDelay: Duration(hours: 24),
        ),
      );
      when(
        () => platform.startSpan(
          any(),
          parentSpanId: any(named: 'parentSpanId'),
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) async => kTestSpanId);
      when(
        () => platform.getTraceId(any()),
      ).thenAnswer((_) async => kTestTraceId);
    });

    test('preserves traceId and spanId across inject and extract', () async {
      await Embrace.instance.startSpan('parent-span');

      final propagator = W3CTraceContextPropagator();

      // Inject current span context into headers.
      final headers = <String, String>{};
      propagator.inject(Context.current, headers, _MapSetter(headers));
      expect(headers['traceparent'], isNotNull);

      // Extract into a fresh context.
      final extracted = propagator.extract(
        ContextCreate.create(),
        headers,
        _MapGetter(headers),
      );

      expect(extracted.spanContext!.traceId.hexString, equals(kTestTraceId));
      expect(extracted.spanContext!.spanId.hexString, equals(kTestSpanId));
      expect(extracted.spanContext!.isRemote, isTrue);
    });

    test('no impact on existing behavior when no context is set', () {
      final propagator = W3CTraceContextPropagator();

      // Inject into empty context — produces no headers.
      final outHeaders = <String, String>{};
      propagator.inject(Context.current, outHeaders, _MapSetter(outHeaders));
      expect(outHeaders, isEmpty);

      // Extract from empty headers — leaves spanContext null.
      final extracted = propagator.extract(
        Context.current,
        <String, String>{},
        _MapGetter(<String, String>{}),
      );
      expect(extracted.spanContext, isNull);
    });
  });
}
