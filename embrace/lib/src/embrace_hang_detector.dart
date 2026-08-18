import 'dart:async';
import 'dart:isolate';

import 'package:embrace_platform_interface/embrace_platform_interface.dart';

/// Configuration for the Dart UI isolate hang detector's ping interval and
/// hang threshold.
class EmbraceHangDetectionConfig {
  /// Creates a hang-detection configuration.
  const EmbraceHangDetectionConfig({
    this.pingInterval = const Duration(milliseconds: 200),
    this.hangThreshold = const Duration(milliseconds: 700),
  });

  /// How often the monitor isolate pings the main isolate. Should be
  /// meaningfully smaller than [hangThreshold] so a hang's start can be
  /// detected with reasonable precision.
  final Duration pingInterval;

  /// How long the main isolate can go without echoing a ping before it's
  /// considered hung.
  final Duration hangThreshold;
}

/// Tracks whether the main isolate has stopped echoing pings, independent of
/// the isolate/timer plumbing that drives it — so the detection logic can be
/// exercised directly in tests.
class EmbraceHangTracker {
  /// Creates a tracker that considers the main isolate hung once
  /// [hangThreshold] has elapsed since the last echo. [initialGoodTime]
  /// seeds the last-known-responsive time, defaulting to now.
  EmbraceHangTracker(this.hangThreshold, {DateTime? initialGoodTime})
      : _lastGoodTime = initialGoodTime ?? DateTime.now();

  /// How long the main isolate can go without echoing a ping before it's
  /// considered hung.
  final Duration hangThreshold;

  DateTime _lastGoodTime;
  DateTime? _hangStartTime;

  /// Call on every ping tick, before sending the ping, to check whether
  /// [now] has crossed [hangThreshold] since the last echo.
  void onTick(DateTime now) {
    if (_hangStartTime == null &&
        now.difference(_lastGoodTime) >= hangThreshold) {
      _hangStartTime = _lastGoodTime;
    }
  }

  /// Call when an echo is received at [now]. Returns the resolved hang
  /// window if a hang was in progress, or `null` if the main isolate was
  /// already responsive.
  ({DateTime start, DateTime end})? onEcho(DateTime now) {
    final hangStart = _hangStartTime;
    _hangStartTime = null;
    _lastGoodTime = now;
    if (hangStart == null) return null;
    return (start: hangStart, end: now);
  }
}

/// Detects when the main (UI) Dart isolate stops responding.
///
/// Flutter's UI thread is a Dart isolate, not the platform's native main
/// thread, so iOS watchdog kills and Android ANR detection never see a
/// frozen Dart event loop. This class spawns a background isolate that
/// pings the main isolate on a fixed interval; if the main isolate doesn't
/// echo a ping within [EmbraceHangDetectionConfig.hangThreshold], the time
/// until it next responds is recorded as a hang.
class EmbraceHangDetector {
  /// Creates a hang detector using [config], or the default configuration
  /// if none is given.
  EmbraceHangDetector({EmbraceHangDetectionConfig? config})
      : _config = config ?? const EmbraceHangDetectionConfig();

  final EmbraceHangDetectionConfig _config;

  ReceivePort? _mainReceivePort;
  Isolate? _monitorIsolate;
  SendPort? _monitorSendPort;

  /// Spawns the monitor isolate and begins pinging the main isolate.
  Future<void> start() async {
    final mainReceivePort = ReceivePort();
    _mainReceivePort = mainReceivePort;
    mainReceivePort.listen(_handleMonitorMessage);

    _monitorIsolate = await Isolate.spawn(
      _monitorEntryPoint,
      [
        mainReceivePort.sendPort,
        _config.pingInterval.inMilliseconds,
        _config.hangThreshold.inMilliseconds,
      ],
    );
  }

  /// Kills the monitor isolate and stops listening for its messages.
  void stop() {
    _monitorIsolate?.kill(priority: Isolate.immediate);
    _monitorIsolate = null;
    _mainReceivePort?.close();
    _mainReceivePort = null;
    _monitorSendPort = null;
  }

  void _handleMonitorMessage(dynamic message) {
    if (message is SendPort) {
      _monitorSendPort = message;
    } else if (message is int) {
      _monitorSendPort?.send(message);
    } else if (message is List) {
      _recordHang(message[0] as int, message[1] as int);
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

void _monitorEntryPoint(List<dynamic> args) {
  final mainSendPort = args[0] as SendPort;
  final pingInterval = Duration(milliseconds: args[1] as int);
  final hangThreshold = Duration(milliseconds: args[2] as int);

  final monitorReceivePort = ReceivePort();
  mainSendPort.send(monitorReceivePort.sendPort);

  final tracker = EmbraceHangTracker(hangThreshold);

  monitorReceivePort.listen((dynamic message) {
    if (message is! int) return;
    final resolved = tracker.onEcho(DateTime.now());
    if (resolved != null) {
      mainSendPort.send([
        resolved.start.millisecondsSinceEpoch,
        resolved.end.millisecondsSinceEpoch,
      ]);
    }
  });

  Timer.periodic(pingInterval, (_) {
    final now = DateTime.now();
    tracker.onTick(now);
    mainSendPort.send(now.millisecondsSinceEpoch);
  });
}
