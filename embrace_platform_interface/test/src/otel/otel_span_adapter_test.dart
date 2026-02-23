import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'otel_test_fixtures.dart';

class MockEmbraceSpanDelegate extends Mock implements EmbraceSpanDelegate {
  MockEmbraceSpanDelegate(this.id);

  @override
  final String id;
}

void main() {
  late MockEmbraceSpanDelegate mockSpan;

  setUp(() {
    mockSpan = MockEmbraceSpanDelegate(kTestSpanId);
    when(() => mockSpan.traceId).thenAnswer((_) async => kTestTraceId);
    when(
      () => mockSpan.stop(
        errorCode: any(named: 'errorCode'),
        endTimeMs: any(named: 'endTimeMs'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => mockSpan.addAttribute(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockSpan.addEvent(
        any(),
        timestampMs: any(named: 'timestampMs'),
        attributes: any(named: 'attributes'),
      ),
    ).thenAnswer((_) async => true);
  });

  group('OTelSpanAdapter.create', () {
    test('resolves name', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.name, kTestSpanName);
    });

    test('spanContext spanId matches native span id', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.spanContext.spanId.hexString, kTestSpanId);
    });

    test('spanContext traceId matches native trace id', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.spanContext.traceId.hexString, kTestTraceId);
    });

    test('spanContext is valid for well-formed IDs', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.spanContext.isValid, isTrue);
    });

    test('spanContext is invalid when traceId is null', () async {
      when(() => mockSpan.traceId).thenAnswer((_) async => null);
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.spanContext.isValid, isFalse);
    });

    test('spanContext is invalid when traceId is wrong length', () async {
      when(() => mockSpan.traceId).thenAnswer((_) async => 'tooshort');
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.spanContext.isValid, isFalse);
    });

    test('spanContext is invalid when traceId contains non-hex characters',
        () async {
      when(() => mockSpan.traceId).thenAnswer(
        (_) async => 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
      );
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.spanContext.isValid, isFalse);
    });

    test('isRecording is true immediately after creation', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.isRecording, isTrue);
    });

    test('status is Unset before end', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.status, SpanStatusCode.Unset);
    });

    test('endTime is null before end', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(adapter.endTime, isNull);
    });
  });

  group('end', () {
    test('delegates to EmbraceSpan.stop', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      verify(() => mockSpan.stop()).called(1);
    });

    test('delegates errorCode to EmbraceSpan.stop', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end(errorCode: ErrorCode.failure);
      verify(
        () => mockSpan.stop(errorCode: ErrorCode.failure),
      ).called(1);
    });

    test('sets isRecording to false', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      expect(adapter.isRecording, isFalse);
    });

    test('sets endTime after end', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      expect(adapter.endTime, isNotNull);
    });

    test('returns false when called a second time', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final result = await adapter.end();
      expect(result, isFalse);
    });

    test('only calls EmbraceSpan.stop once when ended twice', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      await adapter.end();
      verify(() => mockSpan.stop()).called(1);
    });
  });

  group('status mapping', () {
    test('status is Ok after end with no errorCode', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      expect(adapter.status, SpanStatusCode.Ok);
    });

    test('status is Error after end with ErrorCode.failure', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end(errorCode: ErrorCode.failure);
      expect(adapter.status, SpanStatusCode.Error);
    });

    test('status is Error after end with ErrorCode.abandon', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end(errorCode: ErrorCode.abandon);
      expect(adapter.status, SpanStatusCode.Error);
    });

    test('status is Error after end with ErrorCode.unknown', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end(errorCode: ErrorCode.unknown);
      expect(adapter.status, SpanStatusCode.Error);
    });
  });

  group('setStringAttribute', () {
    test('delegates to EmbraceSpan.addAttribute', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.setStringAttribute('key', 'value');
      verify(() => mockSpan.addAttribute('key', 'value')).called(1);
    });

    test('returns the result from EmbraceSpan.addAttribute', () async {
      when(() => mockSpan.addAttribute(any(), any()))
          .thenAnswer((_) async => false);
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      final result = await adapter.setStringAttribute('key', 'value');
      expect(result, isFalse);
    });
  });

  group('addEmbraceEvent', () {
    test('delegates name to EmbraceSpan.addEvent', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.addEmbraceEvent('my-event');
      verify(() => mockSpan.addEvent('my-event')).called(1);
    });

    test('delegates timestampMs and attributes to EmbraceSpan.addEvent',
        () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.addEmbraceEvent(
        'my-event',
        timestampMs: 1000,
        attributes: {'k': 'v'},
      );
      verify(
        () => mockSpan.addEvent(
          'my-event',
          timestampMs: 1000,
          attributes: {'k': 'v'},
        ),
      ).called(1);
    });
  });
}
