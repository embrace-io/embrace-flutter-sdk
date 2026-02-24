import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/src/otel/otel_id_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'otel_test_fixtures.dart';

void main() {
  group('OtelIdUtils.buildSpanContext', () {
    test('returns valid SpanContext for well-formed IDs', () {
      final context =
          OtelIdUtils.buildSpanContext(kTestSpanId, kTestTraceId);
      expect(context.isValid, isTrue);
    });

    test('spanId hex matches input', () {
      final context =
          OtelIdUtils.buildSpanContext(kTestSpanId, kTestTraceId);
      expect(context.spanId.hexString, kTestSpanId);
    });

    test('traceId hex matches input', () {
      final context =
          OtelIdUtils.buildSpanContext(kTestSpanId, kTestTraceId);
      expect(context.traceId.hexString, kTestTraceId);
    });

    test('returns invalid SpanContext when traceId is all zeros', () {
      final context =
          OtelIdUtils.buildSpanContext(kTestSpanId, kInvalidTraceId);
      expect(context.isValid, isFalse);
    });

    test('returns invalid SpanContext when traceId is wrong length', () {
      final context =
          OtelIdUtils.buildSpanContext(kTestSpanId, 'tooshort');
      expect(context.isValid, isFalse);
    });

    test('returns invalid SpanContext when traceId contains non-hex characters',
        () {
      final context = OtelIdUtils.buildSpanContext(
        kTestSpanId,
        'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
      );
      expect(context.isValid, isFalse);
    });

    test('returns invalid SpanContext when spanId is wrong length', () {
      final context =
          OtelIdUtils.buildSpanContext('tooshort', kTestTraceId);
      expect(context.isValid, isFalse);
    });

    test('returns invalid SpanContext when spanId contains non-hex characters',
        () {
      final context =
          OtelIdUtils.buildSpanContext('zzzzzzzzzzzzzzzz', kTestTraceId);
      expect(context.isValid, isFalse);
    });
  });

  group('OtelIdUtils.tryParseHex', () {
    test('returns bytes for valid hex string', () {
      final result = OtelIdUtils.tryParseHex(kTestSpanId, SpanId.spanIdLength);
      expect(result, isNotNull);
      expect(result!.length, SpanId.spanIdLength);
    });

    test('parsed bytes round-trip back to original hex', () {
      final result =
          OtelIdUtils.tryParseHex(kTestTraceId, TraceId.traceIdLength);
      expect(result, isNotNull);
      final hex = result!
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(hex, kTestTraceId);
    });

    test('returns null for wrong-length string', () {
      final result = OtelIdUtils.tryParseHex('tooshort', SpanId.spanIdLength);
      expect(result, isNull);
    });

    test('returns null for non-hex characters', () {
      final result =
          OtelIdUtils.tryParseHex('zzzzzzzzzzzzzzzz', SpanId.spanIdLength);
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = OtelIdUtils.tryParseHex('', SpanId.spanIdLength);
      expect(result, isNull);
    });
  });
}
