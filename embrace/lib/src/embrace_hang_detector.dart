/// Configuration for the Dart UI isolate hang detector's ping interval and
/// hang threshold.
class EmbraceHangDetectionConfig {
  /// Creates a hang-detection configuration.
  const EmbraceHangDetectionConfig({
    this.pingInterval = const Duration(milliseconds: 1000),
    this.hangThreshold = const Duration(milliseconds: 700),
  });

  /// How often the monitor isolate pings the main isolate.
  final Duration pingInterval;

  /// How long the main isolate can go without echoing a ping before it's
  /// considered hung.
  final Duration hangThreshold;
}
