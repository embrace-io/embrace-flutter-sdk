import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/widgets.dart';

/// Measures Flutter time-to-first-frame and records it as an OTel span.
///
/// The start timestamp is captured when this class is first loaded by the Dart
/// runtime — as early in the Dart lifecycle as possible without requiring
/// changes to the app's `main` function. The end time is when the first frame
/// is rasterized to the display, not just composed in Dart.
class EmbraceStartupTracker {
  static late final Stopwatch _stopwatch;
  static late final int _startEpochMs;

  /// Captures the start timestamp. Must be called as early as possible in the
  /// SDK lifecycle, before [recordFirstFrame].
  static void init() {
    _stopwatch = Stopwatch()..start();
    _startEpochMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Waits for the first rasterized frame and records an
  /// `emb-flutter-time-to-first-frame` span covering Dart init → pixels on
  /// screen.
  static Future<void> recordFirstFrame() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    await EmbracePlatform.instance.recordCompletedSpan(
      'emb-flutter-time-to-first-frame',
      _startEpochMs,
      _startEpochMs + elapsedMs,
    );
  }
}
