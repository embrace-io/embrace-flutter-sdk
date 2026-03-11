import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/src/otel/otel_context_utils.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'otel_test_fixtures.dart';

class MockEmbraceSpanDelegate extends Mock implements EmbraceSpanDelegate {
  MockEmbraceSpanDelegate(this.id);

  @override
  final String id;
}

Future<OTelSpanAdapter> _makeAdapter(
  String spanId,
  String spanName,
) async {
  final mock = MockEmbraceSpanDelegate(spanId);
  when(() => mock.traceId).thenAnswer((_) async => kTestTraceId);
  return OTelSpanAdapter.create(spanName, mock);
}

void main() {
  late OTelContextUtils contextUtils;

  setUp(() {
    Context.resetCurrent();
    contextUtils = OTelContextUtils();
  });

  group('OTelContextUtils.currentSpan', () {
    test('returns null when no span is active', () {
      expect(contextUtils.currentSpan(), isNull);
    });
  });

  group('OTelContextUtils.setCurrent', () {
    test('stores adapter in Context and returns the previous Context',
        () async {
      final adapter = await _makeAdapter(kTestSpanId, kTestSpanName);

      final previousContext = contextUtils.setCurrent(adapter);

      expect(previousContext, isA<Context>());
      expect(contextUtils.currentSpan(), same(adapter));
    });

    test('returns previous adapter when one is already current', () async {
      final first = await _makeAdapter(kTestSpanId, 'first');
      final second = await _makeAdapter('b2c3d4e5f6a7b8c9', 'second');

      contextUtils.setCurrent(first);
      final previousContext = contextUtils.setCurrent(second);

      // Restoring the captured context reinstates the first span.
      contextUtils.restore(previousContext);
      expect(contextUtils.currentSpan(), same(first));
    });
  });

  group('OTelContextUtils.restore', () {
    test('currentSpan returns null after restoring the pre-span context',
        () async {
      final adapter = await _makeAdapter(kTestSpanId, kTestSpanName);
      final previousContext = contextUtils.setCurrent(adapter);

      adapter.markEnded();
      contextUtils.restore(previousContext);

      expect(contextUtils.currentSpan(), isNull);
    });

    test('reinstates the previous adapter', () async {
      final parent = await _makeAdapter(kTestSpanId, 'parent');
      final child = await _makeAdapter('b2c3d4e5f6a7b8c9', 'child');

      final beforeParent = contextUtils.setCurrent(parent);
      final beforeChild = contextUtils.setCurrent(child);

      contextUtils.restore(beforeChild);
      expect(contextUtils.currentSpan(), same(parent));

      contextUtils.restore(beforeParent);
      expect(contextUtils.currentSpan(), isNull);
    });
  });

  group('Context propagation across async gaps', () {
    test('current span is visible after an await', () async {
      final adapter = await _makeAdapter(kTestSpanId, kTestSpanName);
      contextUtils.setCurrent(adapter);

      // Simulate an async gap.
      await Future<void>.delayed(Duration.zero);

      expect(contextUtils.currentSpan(), same(adapter));
    });

    test('nested spans restore correctly after async gaps', () async {
      final parent = await _makeAdapter(kTestSpanId, 'parent');
      final child = await _makeAdapter('b2c3d4e5f6a7b8c9', 'child');

      contextUtils.setCurrent(parent);
      await Future<void>.delayed(Duration.zero);

      final beforeChild = contextUtils.setCurrent(child);
      await Future<void>.delayed(Duration.zero);

      expect(contextUtils.currentSpan(), same(child));

      contextUtils.restore(beforeChild);
      await Future<void>.delayed(Duration.zero);

      expect(contextUtils.currentSpan(), same(parent));
    });
  });
}
