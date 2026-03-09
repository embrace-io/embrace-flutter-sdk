import 'dart:async';

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/export_result.dart';
import 'package:embrace/src/otel/stdout_span_exporter.dart';
// ignore: implementation_imports
import 'package:embrace_platform_interface/src/otel/readable_span_data.dart';
import 'package:flutter_test/flutter_test.dart';

ReadableSpanData _makeSpan({
  String name = 'test-span',
  int startTimeMs = 1704067200000,
  int endTimeMs = 1704067200042,
  Map<String, String>? attributes,
  List<Map<String, dynamic>>? events,
}) {
  return ReadableSpanData.fromRaw(
    name: name,
    spanId: 'a1b2c3d4e5f6a7b8',
    traceId: '00112233445566778899aabbccddeeff',
    startTimeMs: startTimeMs,
    endTimeMs: endTimeMs,
    attributes: attributes,
    events: events,
    resource: Attributes.of({}),
  );
}

/// Runs [body] and returns all lines printed via [print].
Future<List<String>> _capturePrint(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  group('StdOutSpanExporter — debug mode', () {
    test('export returns success', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      final result = await exporter.export([_makeSpan()]);
      expect(result, ExportResult.success);
    });

    test('prints one line per span', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      final lines = await _capturePrint(
        () => exporter
            .export([_makeSpan(name: 'span-a'), _makeSpan(name: 'span-b')]),
      );
      expect(lines, hasLength(2));
    });

    test('output contains span name', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      final lines = await _capturePrint(
        () => exporter.export([_makeSpan(name: 'my-span')]),
      );
      expect(lines.first, contains('my-span'));
    });

    test('output contains duration in milliseconds', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      // endTimeMs - startTimeMs = 42ms
      final lines = await _capturePrint(
        () => exporter.export([_makeSpan(startTimeMs: 1000, endTimeMs: 1042)]),
      );
      expect(lines.first, contains('42ms'));
    });

    test('output contains status', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      final lines = await _capturePrint(
        () => exporter.export([_makeSpan()]),
      );
      expect(lines.first, contains('status:'));
    });

    test('output contains attribute count', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      final lines = await _capturePrint(
        () => exporter.export([
          _makeSpan(attributes: {'key1': 'val1', 'key2': 'val2'}),
        ]),
      );
      expect(lines.first, contains('attributes: 2'));
    });

    test('output contains event count', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      final lines = await _capturePrint(
        () => exporter.export([
          _makeSpan(
            events: [
              {'name': 'evt1', 'timestampMs': 1704067200010},
              {'name': 'evt2', 'timestampMs': 1704067200020},
            ],
          ),
        ]),
      );
      expect(lines.first, contains('events: 2'));
    });

    test('forceFlush returns success', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      expect(await exporter.forceFlush(), ExportResult.success);
    });

    test('shutdown completes without error', () async {
      final exporter = StdOutSpanExporter(debugMode: true);
      await expectLater(exporter.shutdown(), completes);
    });
  });

  group('StdOutSpanExporter — release mode', () {
    test('export returns success without printing', () async {
      final exporter = StdOutSpanExporter(debugMode: false);
      final lines = await _capturePrint(
        () => exporter.export([_makeSpan(name: 'silent-span')]),
      );
      expect(lines, isEmpty);
    });

    test('export result is success', () async {
      final exporter = StdOutSpanExporter(debugMode: false);
      final result = await exporter.export([_makeSpan()]);
      expect(result, ExportResult.success);
    });

    test('forceFlush returns success', () async {
      final exporter = StdOutSpanExporter(debugMode: false);
      expect(await exporter.forceFlush(), ExportResult.success);
    });

    test('shutdown completes without error', () async {
      final exporter = StdOutSpanExporter(debugMode: false);
      await expectLater(exporter.shutdown(), completes);
    });
  });
}
