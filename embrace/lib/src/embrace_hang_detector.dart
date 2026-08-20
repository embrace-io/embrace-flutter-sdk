import 'dart:async';
import 'dart:isolate';

import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/widgets.dart';

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

  ReceivePort? _mainReceivePort;
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;
  Isolate? _monitorIsolate;
  SendPort? _monitorSendPort;

  /// Bumped by every [_startMonitoring]/[_stopMonitoring] call so an
  /// in-flight isolate spawn can detect that a later start/stop superseded
  /// it — e.g. a background/foreground flip landing while `Isolate.spawn`
  /// is still resolving — and discard itself instead of overwriting the
  /// newer state.
  int _monitoringGeneration = 0;

  /// Spawns the monitor isolate, begins pinging the main isolate, and starts
  /// observing app lifecycle changes so monitoring can pause while
  /// backgrounded.
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _startMonitoring();
  }

  /// Kills the monitor isolate, stops listening for its messages, and stops
  /// observing app lifecycle changes.
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _stopMonitoring();
      case AppLifecycleState.resumed:
        if (_monitorIsolate == null) {
          unawaited(_startMonitoring());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _startMonitoring() async {
    final generation = ++_monitoringGeneration;

    final mainReceivePort = ReceivePort()..listen(_handleMonitorMessage);
    final errorPort = ReceivePort()..listen(_handleMonitorError);
    final exitPort = ReceivePort()
      ..listen((_) => _closeErrorAndExitPorts());

    final isolate = await Isolate.spawn(
      _monitorEntryPoint,
      [
        mainReceivePort.sendPort,
        _config.pingInterval.inMilliseconds,
        _config.hangThreshold.inMilliseconds,
      ],
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    if (generation != _monitoringGeneration) {
      // A stop (or a newer start) happened while this isolate was
      // spawning. It was never published, so tear it down rather than
      // adopting it over the newer state.
      isolate.kill(priority: Isolate.immediate);
      mainReceivePort.close();
      errorPort.close();
      exitPort.close();
      return;
    }

    _mainReceivePort = mainReceivePort;
    _errorPort = errorPort;
    _exitPort = exitPort;
    _monitorIsolate = isolate;
  }

  void _stopMonitoring() {
    _monitoringGeneration++;
    _monitorIsolate?.kill(priority: Isolate.immediate);
    _monitorIsolate = null;
    _mainReceivePort?.close();
    _mainReceivePort = null;
    _monitorSendPort = null;
    _closeErrorAndExitPorts();
  }

  /// Whether the monitor isolate is currently running. Exposed for testing
  /// the pause/resume behavior around app lifecycle changes.
  @visibleForTesting
  bool get isMonitoring => _monitorIsolate != null;

  void _closeErrorAndExitPorts() {
    _errorPort?.close();
    _errorPort = null;
    _exitPort?.close();
    _exitPort = null;
  }

  /// Handles an uncaught error from the monitor isolate as if it had
  /// arrived over the real error port. Exposed for testing error forwarding
  /// without spawning a real isolate.
  @visibleForTesting
  void handleMonitorError(dynamic message) => _handleMonitorError(message);

  void _handleMonitorError(dynamic message) {
    _closeErrorAndExitPorts();

    final params = message as List<dynamic>;
    final error = params[0] as String;
    final stackTrace = params[1] as String;
    EmbracePlatform.instance.logDartError(
      stackTrace,
      error,
      "Uncaught error in the Dart UI isolate hang detector's monitor "
      'isolate',
      null,
      errorType: 'IsolateUncaughtError',
    );
  }

  /// Handles a message from the monitor isolate as if it had arrived over
  /// the real port. Exposed for testing the reporting mechanism without
  /// spawning a real isolate.
  @visibleForTesting
  void handleMonitorMessage(dynamic message) => _handleMonitorMessage(message);

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
