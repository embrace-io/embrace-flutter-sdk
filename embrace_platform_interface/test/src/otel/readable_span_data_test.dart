import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';
import 'package:embrace_platform_interface/src/otel/readable_span_data.dart';
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
  late Attributes testResource;

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

    testResource = Attributes.of({'service.name': 'test-app'});
  });

  group('ReadableSpanData.fromAdapter', () {
    test('name matches adapter name', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.name, kTestSpanName);
    });

    test('spanContext matches adapter spanContext', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.spanContext, adapter.spanContext);
    });

    test('spanContext spanId matches native span id', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.spanContext.spanId.hexString, kTestSpanId);
    });

    test('spanContext traceId matches native trace id', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.spanContext.traceId.hexString, kTestTraceId);
    });

    test('startTime matches adapter startTime', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.startTime, adapter.startTime);
    });

    test('endTime matches adapter endTime', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.endTime, adapter.endTime);
    });

    test('status is Ok when ended with no errorCode', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.status, SpanStatusCode.Ok);
    });

    test('status is Error when ended with ErrorCode.failure', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end(errorCode: ErrorCode.failure);
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.status, SpanStatusCode.Error);
    });

    test('attributes is empty (native owns attribute state)', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.attributes.isEmpty, isTrue);
    });

    test('events is empty (native owns event state)', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.events, isEmpty);
    });

    test('resource matches supplied resource', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      await adapter.end();
      final data =
          ReadableSpanData.fromAdapter(adapter, resource: testResource);
      expect(data.resource, testResource);
    });

    test('throws ArgumentError when adapter has not been ended', () async {
      final adapter = await OTelSpanAdapter.create(kTestSpanName, mockSpan);
      expect(
        () => ReadableSpanData.fromAdapter(adapter, resource: testResource),
        throwsArgumentError,
      );
    });
  });

  group('ReadableSpanData.fromRaw — core fields', () {
    test('name matches supplied name', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.name, kTestSpanName);
    });

    test('spanContext spanId matches supplied spanId', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.spanContext.spanId.hexString, kTestSpanId);
    });

    test('spanContext traceId matches supplied traceId', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.spanContext.traceId.hexString, kTestTraceId);
    });

    test('spanContext is valid for well-formed IDs', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.spanContext.isValid, isTrue);
    });

    test('spanContext is invalid for malformed traceId', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kInvalidTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.spanContext.isValid, isFalse);
    });

    test('startTime matches millisecond epoch conversion', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(
        data.startTime,
        DateTime.fromMillisecondsSinceEpoch(kTestStartTimeMs),
      );
    });

    test('endTime matches millisecond epoch conversion', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(
        data.endTime,
        DateTime.fromMillisecondsSinceEpoch(kTestEndTimeMs),
      );
    });

    test('status is Ok when errorCode is null', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.status, SpanStatusCode.Ok);
    });

    test('status is Error when errorCode is ErrorCode.failure', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        errorCode: ErrorCode.failure,
        resource: testResource,
      );
      expect(data.status, SpanStatusCode.Error);
    });

    test('status is Error when errorCode is ErrorCode.abandon', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        errorCode: ErrorCode.abandon,
        resource: testResource,
      );
      expect(data.status, SpanStatusCode.Error);
    });

    test('status is Error when errorCode is ErrorCode.unknown', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        errorCode: ErrorCode.unknown,
        resource: testResource,
      );
      expect(data.status, SpanStatusCode.Error);
    });

    test('resource matches supplied resource', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.resource, testResource);
    });
  });

  group('ReadableSpanData.fromRaw — attributes', () {
    test('attributes is empty when null is passed', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.attributes.isEmpty, isTrue);
    });

    test('attributes is empty when empty map is passed', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        attributes: {},
        resource: testResource,
      );
      expect(data.attributes.isEmpty, isTrue);
    });

    test('attributes contains supplied key-value pairs', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        attributes: kTestAttributes,
        resource: testResource,
      );
      final attrMap = data.attributes.toMap();
      expect(attrMap['key']?.value, 'value');
      expect(attrMap['env']?.value, 'test');
    });
  });

  group('ReadableSpanData.fromRaw — events', () {
    test('events is empty when null is passed', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        resource: testResource,
      );
      expect(data.events, isEmpty);
    });

    test('events is empty when empty list is passed', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        events: const [],
        resource: testResource,
      );
      expect(data.events, isEmpty);
    });

    test('events length matches supplied list', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        events: kTestRawEvents,
        resource: testResource,
      );
      expect(data.events.length, kTestRawEvents.length);
    });

    test('event name is correctly mapped', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        events: kTestRawEvents,
        resource: testResource,
      );
      expect(data.events.first.name, 'event-one');
    });

    test('event timestamp matches timestampMs when provided', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        events: kTestRawEvents,
        resource: testResource,
      );
      expect(
        data.events.first.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1704067210000),
      );
    });

    test('event with null timestampMs gets a non-null timestamp', () {
      final before = DateTime.now();
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        events: kTestRawEvents,
        resource: testResource,
      );
      final after = DateTime.now();
      final eventTimestamp = data.events.last.timestamp;
      expect(
        eventTimestamp.isAfter(before) || eventTimestamp == before,
        isTrue,
      );
      expect(
        eventTimestamp.isBefore(after) || eventTimestamp == after,
        isTrue,
      );
    });

    test('event attributes are correctly converted when provided', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        events: kTestRawEvents,
        resource: testResource,
      );
      final eventAttrs = data.events.first.attributes;
      expect(eventAttrs, isNotNull);
      expect(eventAttrs!.toMap()['ek']?.value, 'ev');
    });

    test('event attributes are null when not supplied', () {
      final data = ReadableSpanData.fromRaw(
        name: kTestSpanName,
        spanId: kTestSpanId,
        traceId: kTestTraceId,
        startTimeMs: kTestStartTimeMs,
        endTimeMs: kTestEndTimeMs,
        events: kTestRawEvents,
        resource: testResource,
      );
      expect(data.events.last.attributes, isNull);
    });
  });
}
