import 'dart:async';
import 'dart:collection';

import 'package:embrace/src/otel/embrace_span_exporter.dart';
import 'package:embrace/src/otel/embrace_span_processor_config.dart';
import 'package:embrace_platform_interface/otel.dart';

/// A batching span processor for the Embrace OTel export pipeline.
///
/// Bridges between the Embrace span lifecycle (method channel callbacks) and
/// one or more [EmbraceSpanExporter]s. Completed spans are queued via [onEnd]
/// and flushed to all registered exporters in batches on a configurable
/// schedule.
///
/// Since the native SDK owns span lifecycle, [onStart] is a no-op.
///
/// Example:
/// ```dart
/// final processor = EmbraceSpanProcessor(
///   exporters: [MySpanExporter()],
///   config: EmbraceSpanProcessorConfig(scheduleDelay: Duration(seconds: 2)),
/// );
/// // later, when a span ends:
/// await processor.onEnd(readableSpanData);
/// ```
class EmbraceSpanProcessor {
  /// Creates a new [EmbraceSpanProcessor].
  ///
  /// [exporters] — initial list of [EmbraceSpanExporter]s to register.
  /// Additional exporters can be added later via [addExporter].
  ///
  /// [config] — batch processing configuration. Defaults to
  /// [EmbraceSpanProcessorConfig] with its default values.
  EmbraceSpanProcessor({
    List<EmbraceSpanExporter>? exporters,
    EmbraceSpanProcessorConfig config = const EmbraceSpanProcessorConfig(),
  }) : _config = config {
    if (exporters != null) {
      _exporters.addAll(exporters);
    }
    _timer = Timer.periodic(_config.scheduleDelay, (_) => forceFlush());
  }

  final EmbraceSpanProcessorConfig _config;
  final List<EmbraceSpanExporter> _exporters = [];
  final Queue<ReadableSpanData> _queue = Queue<ReadableSpanData>();
  bool _isShutdown = false;
  Timer? _timer;

  /// Registers an additional [EmbraceSpanExporter].
  ///
  /// No-op if [shutdown] has already been called.
  void addExporter(EmbraceSpanExporter exporter) {
    if (_isShutdown) return;
    _exporters.add(exporter);
  }

  /// Called when a span starts.
  ///
  /// No-op — the native SDK owns span lifecycle. Included for symmetry with
  /// the OTel SpanProcessor pattern so callers can treat this class uniformly.
  void onStart(OTelSpanAdapter adapter) {}

  /// Called when a span ends.
  ///
  /// Queues [spanData] for the next export batch. If the queue has reached
  /// [EmbraceSpanProcessorConfig.maxQueueSize], [spanData] is silently
  /// dropped. No-op after [shutdown].
  Future<void> onEnd(ReadableSpanData spanData) async {
    if (_isShutdown) return;
    if (_queue.length >= _config.maxQueueSize) return;
    _queue.add(spanData);
  }

  /// Exports all currently queued spans to every registered exporter.
  ///
  /// Called automatically on the configured
  /// [EmbraceSpanProcessorConfig.scheduleDelay]. May also be called manually
  /// when an immediate flush is needed. No-op after [shutdown].
  Future<void> forceFlush() async {
    if (_isShutdown) return;
    await _exportBatch();
  }

  /// Flushes remaining spans, shuts down all exporters, and cancels the timer.
  ///
  /// After calling [shutdown], [onEnd] and [addExporter] are no-ops and no
  /// further spans will be exported.
  Future<void> shutdown() async {
    if (_isShutdown) return;
    _isShutdown = true;
    _timer?.cancel();
    _timer = null;
    await _exportBatch();
    for (final exporter in _exporters) {
      await exporter.shutdown();
    }
  }

  Future<void> _exportBatch() async {
    if (_queue.isEmpty || _exporters.isEmpty) return;
    final batch = <ReadableSpanData>[];
    while (batch.length < _config.maxBatchSize && _queue.isNotEmpty) {
      batch.add(_queue.removeFirst());
    }
    for (final exporter in _exporters) {
      await exporter.export(batch);
    }
  }
}
