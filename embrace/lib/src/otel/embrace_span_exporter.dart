import 'package:embrace_platform_interface/otel.dart';

/// Abstract exporter for Embrace-specific span data.
///
/// Implement this to receive completed [ReadableSpanData] objects from the
/// Embrace export pipeline.
abstract class EmbraceSpanExporter {
  /// Exports a batch of completed [ReadableSpanData] objects.
  Future<void> export(List<ReadableSpanData> spans);

  /// Flushes any pending span data.
  Future<void> forceFlush();

  /// Shuts down the exporter, releasing any held resources.
  Future<void> shutdown();
}
