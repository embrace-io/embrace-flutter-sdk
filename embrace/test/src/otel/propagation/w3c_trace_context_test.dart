import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/embrace.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/propagation/w3c_trace_context.dart';
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

void _stubSpanLifecycle(MockEmbracePlatform platform) {
  when(
    () => platform.startSpan(
      any(),
      parentSpanId: any(named: 'parentSpanId'),
      startTimeMs: any(named: 'startTimeMs'),
    ),
  ).thenAnswer((_) async => 'test-span-id');
  when(
    () => platform.stopSpan(any(), endTimeMs: any(named: 'endTimeMs')),
  ).thenAnswer((_) async => true);
}

void _stubGenerateW3cTraceparent(
  MockEmbracePlatform platform,
  String? returnValue,
) {
  when(
    () => platform.generateW3cTraceparent(any(), any()),
  ).thenAnswer((_) async => returnValue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEmbracePlatform platform;
  late EmbraceTracer tracer;

  setUp(() async {
    platform = MockEmbracePlatform();
    EmbracePlatform.instance = platform;
    when(
      () => platform.attachToHostSdk(
        enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
      ),
    ).thenAnswer((_) async => true);

    await Embrace.instance.start();
    _stubSpanLifecycle(platform);
    final provider = OTelAPI.tracerProvider() as EmbraceTracerProvider;
    tracer = provider.getTracer('test') as EmbraceTracer;
  });

  // ignore: invalid_use_of_visible_for_testing_member
  tearDown(OTelAPI.reset);

  group('W3cTraceContext.fromSpanContext', () {
    test('produces correct 55-character traceparent string', () {
      final span = tracer.createSpan(name: 'test');
      final result = W3cTraceContext.fromSpanContext(span.spanContext);

      expect(result, isNotNull);
      expect(result!.length, 55);
      expect(result, matches(r'^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$'));
    });

    test('encodes traceId and spanId correctly', () {
      final span = tracer.createSpan(name: 'test');
      final sc = span.spanContext;
      final result = W3cTraceContext.fromSpanContext(sc);

      expect(result, isNotNull);
      final parts = result!.split('-');
      expect(parts[0], '00');
      expect(parts[1], sc.traceId.toString());
      expect(parts[2], sc.spanId.toString());
    });

    test('returns null for invalid (zero) SpanContext', () {
      final invalidCtx = OTelAPI.spanContextInvalid();

      expect(W3cTraceContext.fromSpanContext(invalidCtx), isNull);
    });
  });

  group('W3cTraceContext.extract', () {
    test('parses a valid header and returns a matching SpanContext', () {
      final span = tracer.createSpan(name: 'test');
      final sc = span.spanContext;
      final header = W3cTraceContext.fromSpanContext(sc)!;

      final extracted = W3cTraceContext.extract(header);

      expect(extracted, isNotNull);
      expect(extracted!.traceId, sc.traceId);
      expect(extracted.spanId, sc.spanId);
      expect(extracted.isRemote, isTrue);
    });

    test('returns null for null input', () {
      expect(W3cTraceContext.extract(null), isNull);
    });

    test('returns null for wrong number of segments', () {
      expect(W3cTraceContext.extract('00-abc'), isNull);
    });

    test('parses header with non-00 version', () {
      final span = tracer.createSpan(name: 'test');
      final sc = span.spanContext;
      final header = 'ff-${sc.traceId.hexString}-${sc.spanId.hexString}-01';

      final extracted = W3cTraceContext.extract(header);

      expect(extracted, isNotNull);
      expect(extracted!.traceId, sc.traceId);
      expect(extracted.spanId, sc.spanId);
    });

    test('returns null for traceId with wrong length', () {
      final span = tracer.createSpan(name: 'test');
      final sc = span.spanContext;
      final header = '00-short-${sc.spanId}-01';

      expect(W3cTraceContext.extract(header), isNull);
    });

    test('returns null for spanId with wrong length', () {
      final span = tracer.createSpan(name: 'test');
      final sc = span.spanContext;
      final header = '00-${sc.traceId}-short-01';

      expect(W3cTraceContext.extract(header), isNull);
    });

    test('returns null for non-hex flags', () {
      final span = tracer.createSpan(name: 'test');
      final sc = span.spanContext;
      final header = '00-${sc.traceId}-${sc.spanId}-zz';

      expect(W3cTraceContext.extract(header), isNull);
    });
  });

  group('W3cTraceContext.injectCurrent', () {
    test('calls generateW3cTraceparent with correct hex strings', () async {
      final span = tracer.startSpan('test');
      final sc = span.spanContext;
      _stubGenerateW3cTraceparent(
        platform,
        '00-${sc.traceId}-${sc.spanId}-01',
      );
      final headers = <String, String>{};

      await W3cTraceContext.injectCurrent(headers);

      verify(
        () => platform.generateW3cTraceparent(
          sc.traceId.toString(),
          sc.spanId.toString(),
        ),
      ).called(1);

      span.end();
    });

    test('sets traceparent header to platform-returned value', () async {
      final span = tracer.startSpan('test');
      const platformValue =
          '00-aaaabbbbccccdddd0000111122223333-0102030405060708-01';
      _stubGenerateW3cTraceparent(platform, platformValue);
      final headers = <String, String>{};

      await W3cTraceContext.injectCurrent(headers);

      expect(headers['traceparent'], platformValue);

      span.end();
    });

    test('uses Dart fallback when platform returns null', () async {
      final span = tracer.startSpan('test');
      final sc = span.spanContext;
      _stubGenerateW3cTraceparent(platform, null);
      final headers = <String, String>{};

      await W3cTraceContext.injectCurrent(headers);

      verify(
        () => platform.generateW3cTraceparent(
          sc.traceId.toString(),
          sc.spanId.toString(),
        ),
      ).called(1);
      expect(headers['traceparent'], W3cTraceContext.fromSpanContext(sc));

      span.end();
    });

    test('is a no-op when no span is active', () async {
      final headers = <String, String>{};

      await W3cTraceContext.injectCurrent(headers);

      expect(headers, isEmpty);
      verifyNever(() => platform.generateW3cTraceparent(any(), any()));
    });
  });

  group('W3cTraceContext.injectCurrentSync', () {
    test('constructs traceparent without calling the platform', () {
      final span = tracer.startSpan('test');
      final sc = span.spanContext;
      final headers = <String, String>{};

      W3cTraceContext.injectCurrentSync(headers);

      expect(headers['traceparent'], W3cTraceContext.fromSpanContext(sc));
      verifyNever(() => platform.generateW3cTraceparent(any(), any()));

      span.end();
    });

    test('is a no-op when no span is active', () {
      final headers = <String, String>{};

      W3cTraceContext.injectCurrentSync(headers);

      expect(headers, isEmpty);
    });
  });
}
