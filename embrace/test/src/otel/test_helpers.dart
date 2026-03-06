import 'package:embrace/src/otel/embrace_span_exporter.dart';
import 'package:embrace/src/otel/export_result.dart';
// ignore: implementation_imports
import 'package:embrace_platform_interface/src/otel/readable_span_data.dart';

/// A test double for [EmbraceSpanExporter] that records all exported spans.
class CapturingSpanExporter implements EmbraceSpanExporter {
  final List<ReadableSpanData> captured = [];

  @override
  Future<ExportResult> export(List<ReadableSpanData> spans) async {
    captured.addAll(spans);
    return ExportResult.success;
  }

  @override
  Future<ExportResult> forceFlush() async => ExportResult.success;

  @override
  Future<void> shutdown() async {}
}
