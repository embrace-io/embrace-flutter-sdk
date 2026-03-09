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
  setUp(Context.resetCurrent);

  group('OTelContextUtils.currentSpan', () {
    test('returns null when no span is active', () {
      expect(OTelContextUtils.currentSpan(), isNull);
    });
  });

  group('OTelContextUtils.setCurrent', () {
    test('stores adapter in Context and returns null when no previous',
        () async {
      final adapter = await _makeAdapter(kTestSpanId, kTestSpanName);

      final previous = OTelContextUtils.setCurrent(adapter);

      expect(previous, isNull);
      expect(OTelContextUtils.currentSpan(), same(adapter));
    });

    test('returns previous adapter when one is already current', () async {
      final first = await _makeAdapter(kTestSpanId, 'first');
      final second = await _makeAdapter('b2c3d4e5f6a7b8c9', 'second');

      OTelContextUtils.setCurrent(first);
      final previous = OTelContextUtils.setCurrent(second);

      expect(previous, same(first));
      expect(OTelContextUtils.currentSpan(), same(second));
    });
  });

  group('OTelContextUtils.restore', () {
    test('clears the current span when previous is null', () async {
      final adapter = await _makeAdapter(kTestSpanId, kTestSpanName);
      OTelContextUtils.setCurrent(adapter);

      OTelContextUtils.restore(null);

      expect(OTelContextUtils.currentSpan(), isNull);
    });

    test('reinstates the previous adapter', () async {
      final parent = await _makeAdapter(kTestSpanId, 'parent');
      final child = await _makeAdapter('b2c3d4e5f6a7b8c9', 'child');

      OTelContextUtils.setCurrent(parent);
      OTelContextUtils.setCurrent(child);

      OTelContextUtils.restore(parent);

      expect(OTelContextUtils.currentSpan(), same(parent));
    });
  });

  group('Context propagation across async gaps', () {
    test('current span is visible after an await', () async {
      final adapter = await _makeAdapter(kTestSpanId, kTestSpanName);
      OTelContextUtils.setCurrent(adapter);

      // Simulate an async gap.
      await Future<void>.delayed(Duration.zero);

      expect(OTelContextUtils.currentSpan(), same(adapter));
    });

    test('nested spans restore correctly after async gaps', () async {
      final parent = await _makeAdapter(kTestSpanId, 'parent');
      final child = await _makeAdapter('b2c3d4e5f6a7b8c9', 'child');

      OTelContextUtils.setCurrent(parent);
      await Future<void>.delayed(Duration.zero);

      final previous = OTelContextUtils.setCurrent(child);
      await Future<void>.delayed(Duration.zero);

      expect(OTelContextUtils.currentSpan(), same(child));

      OTelContextUtils.restore(previous);
      await Future<void>.delayed(Duration.zero);

      expect(OTelContextUtils.currentSpan(), same(parent));
    });
  });
}
