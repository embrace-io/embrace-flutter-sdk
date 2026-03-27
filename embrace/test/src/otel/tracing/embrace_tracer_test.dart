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

void _stubStartSpan(MockEmbracePlatform platform) {
  when(
    () => platform.startSpan(
      any(),
      parentSpanId: any(named: 'parentSpanId'),
      startTimeMs: any(named: 'startTimeMs'),
    ),
  ).thenAnswer((_) async => 'span-id-123');
}

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
    () => platform.addSpanLink(any(), any(), any(), any()),
  ).thenAnswer((_) async => true);
}

Future<void> _pump() => Future.microtask(() {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEmbracePlatform platform;
  late EmbraceTracer tracer;
  late EmbraceTracerProvider provider;

  setUp(() async {
    platform = MockEmbracePlatform();
    EmbracePlatform.instance = platform;
    when(
      () => platform.attachToHostSdk(
        enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
      ),
    ).thenAnswer((_) async => true);

    await Embrace.instance.start();
    provider = OTelAPI.tracerProvider() as EmbraceTracerProvider;
    tracer = provider.getTracer('test') as EmbraceTracer;
  });

  // ignore: invalid_use_of_visible_for_testing_member
  tearDown(OTelAPI.reset);

  group('EmbraceTracer', () {
    group('startSpan', () {
      test('calls platform with name', () {
        _stubStartSpan(platform);

        tracer.startSpan('op');

        verify(() => platform.startSpan('op')).called(1);
      });

      test('passes parentSpanId when explicit parentSpan is given', () {
        _stubStartSpan(platform);

        final parent = tracer.startSpan('parent');
        final expectedParentId = parent.spanContext.spanId.toString();

        tracer.startSpan('child', parentSpan: parent);

        verify(
          () => platform.startSpan(
            'child',
            parentSpanId: expectedParentId,
          ),
        ).called(1);
      });

      test('passes null parentSpanId when no parent or context span', () {
        _stubStartSpan(platform);

        tracer.startSpan('root');

        verify(() => platform.startSpan('root')).called(1);
      });

      test('returns a no-op span without calling platform when disabled', () {
        provider.enabled = false;

        tracer.startSpan('op');

        verifyNever(
          () => platform.startSpan(
            any(),
            parentSpanId: any(named: 'parentSpanId'),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        );
      });

      test('returns a span instance', () {
        _stubStartSpan(platform);

        final span = tracer.startSpan('op');

        expect(span, isA<APISpan>());
      });

      test('forwards attributes to addSpanAttribute', () async {
        _stubStartSpan(platform);
        _stubSpanMutations(platform);

        tracer.startSpan('op', attributes: Attributes.of({'k': 'v'}));
        await _pump();

        verify(
          () => platform.addSpanAttribute('span-id-123', 'k', 'v'),
        ).called(1);
      });

      test('forwards links to addSpanLink', () async {
        _stubStartSpan(platform);
        _stubSpanMutations(platform);

        final linkedTraceId = OTelFactory.otelFactory!.traceId();
        final linkedSpanId = OTelFactory.otelFactory!.spanId();
        final linkedContext = OTelFactory.otelFactory!.spanContext(
          traceId: linkedTraceId,
          spanId: linkedSpanId,
          parentSpanId: OTelFactory.otelFactory!.spanIdInvalid(),
        );
        final link = SpanLinkCreate.create(spanContext: linkedContext);
        tracer.startSpan('op', links: [link]);
        await _pump();

        verify(
          () => platform.addSpanLink(
            'span-id-123',
            linkedTraceId.toString(),
            linkedSpanId.toString(),
            any(),
          ),
        ).called(1);
      });
    });

    group('createSpan', () {
      test('calls platform with name', () {
        _stubStartSpan(platform);

        tracer.createSpan(name: 'op');

        verify(() => platform.startSpan('op')).called(1);
      });

      test('passes startTimeMs when startTime is given', () {
        _stubStartSpan(platform);

        final startTime = DateTime.fromMillisecondsSinceEpoch(1234567890);
        tracer.createSpan(name: 'op', startTime: startTime);

        verify(
          () => platform.startSpan(
            'op',
            startTimeMs: 1234567890,
          ),
        ).called(1);
      });

      test('passes parentSpanId when explicit parentSpan is given', () {
        _stubStartSpan(platform);

        final parent = tracer.startSpan('parent');
        final expectedParentId = parent.spanContext.spanId.toString();

        tracer.createSpan(name: 'child', parentSpan: parent);

        verify(
          () => platform.startSpan(
            'child',
            parentSpanId: expectedParentId,
          ),
        ).called(1);
      });

      test('returns a no-op span without calling platform when disabled', () {
        provider.enabled = false;

        tracer.createSpan(name: 'op');

        verifyNever(
          () => platform.startSpan(
            any(),
            parentSpanId: any(named: 'parentSpanId'),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        );
      });

      test('returns a span instance', () {
        _stubStartSpan(platform);

        final span = tracer.createSpan(name: 'op');

        expect(span, isA<APISpan>());
      });

      test('forwards attributes to addSpanAttribute', () async {
        _stubStartSpan(platform);
        _stubSpanMutations(platform);

        tracer.createSpan(name: 'op', attributes: Attributes.of({'k': 'v'}));
        await _pump();

        verify(
          () => platform.addSpanAttribute('span-id-123', 'k', 'v'),
        ).called(1);
      });

      test('forwards links to addSpanLink', () async {
        _stubStartSpan(platform);
        _stubSpanMutations(platform);

        final linkedTraceId = OTelFactory.otelFactory!.traceId();
        final linkedSpanId = OTelFactory.otelFactory!.spanId();
        final linkedContext = OTelFactory.otelFactory!.spanContext(
          traceId: linkedTraceId,
          spanId: linkedSpanId,
          parentSpanId: OTelFactory.otelFactory!.spanIdInvalid(),
        );
        final link = SpanLinkCreate.create(spanContext: linkedContext);
        tracer.createSpan(name: 'op', links: [link]);
        await _pump();

        verify(
          () => platform.addSpanLink(
            'span-id-123',
            linkedTraceId.toString(),
            linkedSpanId.toString(),
            any(),
          ),
        ).called(1);
      });

      test('forwards spanEvents to addSpanEvent', () async {
        _stubStartSpan(platform);
        _stubSpanMutations(platform);

        final event = SpanEventCreate.create(
          name: 'my-event',
          timestamp: DateTime.now(),
        );
        tracer.createSpan(name: 'op', spanEvents: [event]);
        await _pump();

        verify(
          () => platform.addSpanEvent(
            'span-id-123',
            'my-event',
            timestampMs: any(named: 'timestampMs'),
            attributes: any(named: 'attributes'),
          ),
        ).called(1);
      });
    });

    test('enabled reflects provider.enabled', () {
      expect(tracer.enabled, isTrue);

      provider.enabled = false;

      expect(tracer.enabled, isFalse);
    });

    test('enabled is false after provider.shutdown()', () async {
      expect(tracer.enabled, isTrue);

      await provider.shutdown();

      expect(tracer.enabled, isFalse);
    });
  });
}
