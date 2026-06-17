import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';

@internal
class EmbraceFrameDetectionConfig {
  const EmbraceFrameDetectionConfig({
    this.slowFrameThresholdMs = 16,
    this.frozenFrameThresholdMs = 700,
    this.slowFrameBatchSize = 60,
  });

  final int slowFrameThresholdMs;
  final int frozenFrameThresholdMs;

  final int slowFrameBatchSize;
}

@internal
class EmbraceFrameDetector {
  EmbraceFrameDetector({EmbraceFrameDetectionConfig? config})
      : _config = config ?? const EmbraceFrameDetectionConfig();

  final EmbraceFrameDetectionConfig _config;
  int _slowFrameCount = 0;
  int _worstSlowBuildMs = 0;
  int _worstSlowRasterMs = 0;
  String? _currentRoute;

  void start() {
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void stop() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void setRoute(String? route) {
    _currentRoute = route;
  }

  @visibleForTesting
  void handleTimings(List<FrameTiming> timings) => _onTimings(timings);

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMilliseconds;
      final rasterMs = timing.rasterDuration.inMilliseconds;

      if (buildMs >= _config.frozenFrameThresholdMs ||
          rasterMs >= _config.frozenFrameThresholdMs) {
        EmbracePlatform.instance.logWarning(
          'frozen-frame',
          {
            'build_ms': '$buildMs',
            'raster_ms': '$rasterMs',
            if (_currentRoute != null) 'route': _currentRoute!,
          },
        );
      } else if (buildMs > _config.slowFrameThresholdMs ||
          rasterMs > _config.slowFrameThresholdMs) {
        _slowFrameCount++;
        if (buildMs > _worstSlowBuildMs) _worstSlowBuildMs = buildMs;
        if (rasterMs > _worstSlowRasterMs) _worstSlowRasterMs = rasterMs;

        if (_slowFrameCount >= _config.slowFrameBatchSize) {
          _flushSlowFrames();
        }
      }
    }
  }

  void _flushSlowFrames() {
    EmbracePlatform.instance.logInfo(
      'slow-frames',
      {
        'count': '$_slowFrameCount',
        'worst_build_ms': '$_worstSlowBuildMs',
        'worst_raster_ms': '$_worstSlowRasterMs',
        if (_currentRoute != null) 'route': _currentRoute!,
      },
    );
    _slowFrameCount = 0;
    _worstSlowBuildMs = 0;
    _worstSlowRasterMs = 0;
  }
}
