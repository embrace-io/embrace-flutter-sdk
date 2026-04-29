import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/widgets.dart';

/// Measures Flutter time-to-first-frame and records it as an OTel span.
///
/// The start timestamp is captured when this class is first loaded by the Dart
/// runtime — as early in the Dart lifecycle as possible without requiring
/// changes to the app's `main` function. The end time is when the first frame
/// is rasterized to the display, not just composed in Dart.
class EmbraceStartupTracker {
  static Stopwatch? _stopwatch;
  static int? _startEpochMs;

  /// Captures the start timestamp. Must be called as early as possible in the
  /// SDK lifecycle, before [recordFirstFrame]. Safe to call multiple times —
  /// only the first call sets the timestamp.
  static void init() {
    _stopwatch ??= Stopwatch()..start();
    _startEpochMs ??= DateTime.now().millisecondsSinceEpoch;
  }

  @visibleForTesting
  static void resetForTesting() {
    _stopwatch = null;
    _startEpochMs = null;
  }

  /// Waits for the first rasterized frame and records an
  /// `emb-flutter-time-to-first-frame` span covering Dart init → pixels on
  /// screen.
  static Future<void> recordFirstFrame() async {
    final stopwatch = _stopwatch;
    final startEpochMs = _startEpochMs;
    if (stopwatch == null || startEpochMs == null) return;

    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    final elapsedMs = stopwatch.elapsedMilliseconds;
    await EmbracePlatform.instance.recordCompletedSpan(
      'emb-flutter-time-to-first-frame',
      startEpochMs,
      startEpochMs + elapsedMs,
    );
  }
}
