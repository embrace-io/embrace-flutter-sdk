/// Configuration for `EmbraceSpanProcessor`.
class EmbraceSpanProcessorConfig {
  /// Creates a new [EmbraceSpanProcessorConfig].
  ///
  /// [maxQueueSize] — maximum number of spans that can be queued before new
  /// spans are dropped. Defaults to 2048.
  ///
  /// [maxBatchSize] — maximum number of spans exported in a single batch.
  /// Defaults to 512.
  ///
  /// [scheduleDelay] — interval between periodic batch flushes.
  /// Defaults to 5 seconds.
  ///
  /// [exportTimeout] — maximum time to wait for a batch export or flush to
  /// complete before timing out. Defaults to 30 seconds.
  const EmbraceSpanProcessorConfig({
    this.maxQueueSize = 2048,
    this.maxBatchSize = 512,
    this.scheduleDelay = const Duration(seconds: 5),
    this.exportTimeout = const Duration(seconds: 30),
  });

  /// Maximum number of spans that can be queued before new spans are dropped.
  final int maxQueueSize;

  /// Maximum number of spans exported in a single batch.
  final int maxBatchSize;

  /// Interval between periodic batch flushes.
  final Duration scheduleDelay;

  /// Maximum time to wait for a batch export or flush before timing out.
  final Duration exportTimeout;
}
