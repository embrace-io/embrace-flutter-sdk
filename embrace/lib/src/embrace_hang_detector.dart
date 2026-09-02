import 'dart:async';

import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

EmbraceHangDetector? _activeDetector;

@internal
// Called by Embrace.disable() to tear down hang detection.
void stopActiveHangDetector() {
  _activeDetector?.stop();
}

/// Configuration for the Dart UI isolate hang detector's tick interval and
/// hang threshold.
class EmbraceHangDetectionConfig {
  /// Creates a hang-detection configuration.
  const EmbraceHangDetectionConfig({
    this.tickInterval = const Duration(milliseconds: 200),
    this.hangThreshold = const Duration(milliseconds: 700),
  });

  /// How often the detector's timer ticks on the main isolate. Should be
  /// meaningfully smaller than [hangThreshold] so a hang's start can be
  /// detected with reasonable precision.
  final Duration tickInterval;

  /// How long the main isolate's event loop can go without processing a
  /// scheduled tick before it's considered hung.
  final Duration hangThreshold;
}

/// Tracks whether the main isolate's event loop has stalled, independent of
/// the timer plumbing that drives it — so the detection logic can be
/// exercised directly in tests.
class EmbraceHangTracker {
  /// Creates a tracker that considers the main isolate hung once
  /// [hangThreshold] has elapsed since the last tick. [initialGoodTime]
  /// seeds the last-known-responsive time, defaulting to now.
  EmbraceHangTracker(this.hangThreshold, {DateTime? initialGoodTime})
      : _lastGoodTime = initialGoodTime ?? DateTime.now();

  /// How long the main isolate's event loop can go without processing a
  /// scheduled tick before it's considered hung.
  final Duration hangThreshold;

  DateTime _lastGoodTime;

  /// Call every time the timer ticks, with the current time. A timer tick
  /// firing at all proves the event loop just ran, so a gap since the last
  /// tick that crosses [hangThreshold] means the event loop was stalled for
  /// that whole gap. Returns the resolved hang window if one is found, or
  /// `null` if [now] is within [hangThreshold] of the last tick.
  ({DateTime start, DateTime end})? onTick(DateTime now) {
    final lastGoodTime = _lastGoodTime;
    _lastGoodTime = now;
    if (now.difference(lastGoodTime) < hangThreshold) return null;
    return (start: lastGoodTime, end: now);
  }
}

/// Detects when the main (UI) Dart isolate's event loop stalls.
///
/// Flutter's UI thread is a Dart isolate, not the platform's native main
/// thread, so iOS watchdog kills and Android ANR detection never see a
/// frozen Dart event loop. This class runs a periodic timer directly on the
/// main isolate; a timer tick firing late — more than
/// [EmbraceHangDetectionConfig.hangThreshold] after the previous one — means
/// the event loop was stalled for that gap, which is recorded as a hang.
///
/// Monitoring pauses while the app is backgrounded and restarts fresh on
/// foreground, since the OS may suspend the process while backgrounded —
/// without this, resuming would otherwise look like an isolate hang lasting
/// the entire time in the background.
class EmbraceHangDetector with WidgetsBindingObserver {
  /// Creates a hang detector using [config], or the default configuration
  /// if none is given.
  EmbraceHangDetector({EmbraceHangDetectionConfig? config})
      : _config = config ?? const EmbraceHangDetectionConfig();

  final EmbraceHangDetectionConfig _config;

  EmbraceHangTracker? _tracker;
  Timer? _tickTimer;

  /// Begins the periodic tick timer and starts observing app lifecycle
  /// changes so monitoring can pause while backgrounded.
  Future<void> start() async {
    _activeDetector = this;
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
  }

  /// Stops the tick timer and stops observing app lifecycle changes.
  void stop() {
    if (_activeDetector == this) _activeDetector = null;
    WidgetsBinding.instance.removeObserver(this);
    _stopMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _stopMonitoring();
      case AppLifecycleState.resumed:
        if (_tickTimer == null) _startMonitoring();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _startMonitoring() {
    _tracker = EmbraceHangTracker(_config.hangThreshold);
    _tickTimer = Timer.periodic(
      _config.tickInterval,
      (_) => _handleTick(DateTime.now()),
    );
  }

  void _stopMonitoring() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _tracker = null;
  }

  /// Whether the tick timer is currently running. Exposed for testing the
  /// pause/resume behavior around app lifecycle changes.
  @visibleForTesting
  bool get isMonitoring => _tickTimer != null;

  /// Handles a timer tick as if it had fired at [now]. Exposed for testing
  /// the reporting mechanism without waiting on a real timer.
  @visibleForTesting
  void handleTick(DateTime now) => _handleTick(now);

  void _handleTick(DateTime now) {
    final resolved = _tracker?.onTick(now);
    if (resolved != null) {
      unawaited(
        _recordHang(
          resolved.start.millisecondsSinceEpoch,
          resolved.end.millisecondsSinceEpoch,
        ),
      );
    }
  }

  Future<bool> _recordHang(int startTimeMs, int endTimeMs) {
    return EmbracePlatform.instance.recordCompletedSpan(
      'emb-dart-isolate-hang',
      startTimeMs,
      endTimeMs,
      attributes: {'duration_ms': (endTimeMs - startTimeMs).toString()},
    );
  }
}
