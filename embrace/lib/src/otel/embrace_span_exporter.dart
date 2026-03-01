import 'package:embrace/src/otel/export_result.dart';
import 'package:embrace_platform_interface/otel.dart';

/// Abstract exporter for Embrace-specific span data.
///
/// Implement this to receive completed [ReadableSpanData] objects from the
/// Embrace export pipeline.
abstract class EmbraceSpanExporter {
  /// Exports a batch of completed [ReadableSpanData] objects.
  ///
  /// Returns [ExportResult.success] if all spans were exported successfully,
  /// or [ExportResult.failure] otherwise.
  Future<ExportResult> export(List<ReadableSpanData> spans);

  /// Flushes any pending span data.
  ///
  /// Returns [ExportResult.success] if the flush completed successfully,
  /// or [ExportResult.failure] otherwise.
  Future<ExportResult> forceFlush();

  /// Shuts down the exporter, releasing any held resources.
  Future<void> shutdown();
}
