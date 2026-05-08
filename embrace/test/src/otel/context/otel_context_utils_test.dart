import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/embrace.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/context/otel_context_utils.dart';
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
  ).thenAnswer((_) async => 'test-span-id');
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
    _stubStartSpan(platform);
    final provider = OTelAPI.tracerProvider() as EmbraceTracerProvider;
    tracer = provider.getTracer('test') as EmbraceTracer;
  });

  // ignore: invalid_use_of_visible_for_testing_member
  tearDown(OTelAPI.reset);

  group('OTelContextUtils', () {
    test('currentSpan() returns null when no span is active', () {
      expect(OTelContextUtils.currentSpan(), isNull);
    });

    test('currentSpan() returns span inside withSpan', () {
      final span = tracer.createSpan(name: 'test');

      tracer.withSpan(span, () {
        expect(OTelContextUtils.currentSpan(), same(span));
      });
    });

    test('currentSpan() returns null outside withSpan', () {
      final span = tracer.createSpan(name: 'test');
      tracer.withSpan(span, () {});

      expect(OTelContextUtils.currentSpan(), isNull);
    });

    test('currentSpanContext() returns null when no span is active', () {
      expect(OTelContextUtils.currentSpanContext(), isNull);
    });

    test('currentSpanContext() returns spanContext inside withSpan', () {
      final span = tracer.createSpan(name: 'test');

      tracer.withSpan(span, () {
        expect(
          OTelContextUtils.currentSpanContext(),
          equals(span.spanContext),
        );
      });
    });
  });
}
