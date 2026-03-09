import 'package:embrace/src/otel/embrace_span_exporter.dart';
import 'package:embrace/src/otel/export_result.dart';
import 'package:embrace_platform_interface/otel.dart';
import 'package:flutter/foundation.dart';

/// A [EmbraceSpanExporter] that logs span data to stdout.
///
/// In debug mode ([kDebugMode]), each exported span is printed with its name,
/// duration, status, attribute count, and event count. In release mode, this
/// exporter is a no-op.
///
/// This exporter serves as the default exporter for the Embrace export
/// pipeline and as a reference implementation for users creating custom
/// exporters.
///
/// Example output:
/// ```
/// [Embrace] Span: my-span | duration: 42ms | status: SpanStatusCode.Ok |
///   attributes: 3 | events: 1
/// ```
class StdOutSpanExporter implements EmbraceSpanExporter {
  /// Creates a [StdOutSpanExporter].
  ///
  /// [debugMode] overrides [kDebugMode] for testing purposes.
  StdOutSpanExporter({@visibleForTesting bool? debugMode})
      : _debugMode = debugMode;

  final bool? _debugMode;

  bool get _isDebug => _debugMode ?? kDebugMode;

  @override
  Future<ExportResult> export(List<ReadableSpanData> spans) async {
    if (!_isDebug) return ExportResult.success;
    for (final span in spans) {
      final duration = span.endTime.difference(span.startTime);
      // ignore: avoid_print
      print(
        '[Embrace] Span: ${span.name} | '
        'duration: ${duration.inMilliseconds}ms | '
        'status: ${span.status} | '
        'attributes: ${span.attributes.toMap().length} | '
        'events: ${span.events.length}',
      );
    }
    return ExportResult.success;
  }

  @override
  Future<ExportResult> forceFlush() async => ExportResult.success;

  @override
  Future<void> shutdown() async {}
}
