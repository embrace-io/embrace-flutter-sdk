import 'dart:ui';

import 'package:embrace/src/embrace_frame_detector.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

// Builds a FrameTiming with the given build and raster durations in ms.
FrameTiming _frameTiming({int buildMs = 0, int rasterMs = 0}) {
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: buildMs * 1000,
    rasterStart: 0,
    rasterFinish: rasterMs * 1000,
    rasterFinishWallTime: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockEmbracePlatform platform;
  late EmbraceFrameDetector detector;

  setUp(() {
    platform = _MockEmbracePlatform();
    EmbracePlatform.instance = platform;
    detector = EmbraceFrameDetector();
  });

  group('EmbraceFrameDetectionConfig', () {
    test('has expected defaults', () {
      const config = EmbraceFrameDetectionConfig();
      expect(config.slowFrameThresholdMs, 16);
      expect(config.frozenFrameThresholdMs, 700);
      expect(config.slowFrameBatchSize, 60);
    });

    test('accepts custom values', () {
      const config = EmbraceFrameDetectionConfig(
        slowFrameThresholdMs: 8,
        frozenFrameThresholdMs: 500,
        slowFrameBatchSize: 10,
      );
      expect(config.slowFrameThresholdMs, 8);
      expect(config.frozenFrameThresholdMs, 500);
      expect(config.slowFrameBatchSize, 10);
    });
  });

  group('EmbraceFrameDetector', () {
    group('normal frames', () {
      test('does not report frames at or below slow threshold', () {
        detector.handleTimings([_frameTiming(buildMs: 16)]);
        verifyNever(() => platform.logWarning(any(), any()));
        verifyNever(() => platform.logInfo(any(), any()));
      });
    });

    group('slow frames', () {
      test('does not report before batch size is reached', () {
        detector.handleTimings([_frameTiming(buildMs: 17)]);
        verifyNever(() => platform.logInfo(any(), any()));
      });

      test('reports slow-frames log when batch size is reached', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 3),
        )
          ..handleTimings([_frameTiming(buildMs: 20)])
          ..handleTimings([_frameTiming(buildMs: 30)])
          ..handleTimings([_frameTiming(buildMs: 25)]);

        verify(
          () => platform.logInfo('slow-frames', {
            'count': '3',
            'worst_build_ms': '30',
            'worst_raster_ms': '0',
          }),
        ).called(1);
      });

      test('resets count and worst timings after flush', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 2),
        )
          // First batch.
          ..handleTimings([_frameTiming(buildMs: 50)])
          ..handleTimings([_frameTiming(buildMs: 60)])
          // Second batch — worst should reset.
          ..handleTimings([_frameTiming(buildMs: 20)])
          ..handleTimings([_frameTiming(buildMs: 25)]);

        verifyInOrder([
          () => platform.logInfo('slow-frames', {
                'count': '2',
                'worst_build_ms': '60',
                'worst_raster_ms': '0',
              }),
          () => platform.logInfo('slow-frames', {
                'count': '2',
                'worst_build_ms': '25',
                'worst_raster_ms': '0',
              }),
        ]);
      });

      test('tracks worst raster duration across batch', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 2),
        )
          ..handleTimings([_frameTiming(rasterMs: 50)])
          ..handleTimings([_frameTiming(rasterMs: 20)]);

        verify(
          () => platform.logInfo('slow-frames', {
            'count': '2',
            'worst_build_ms': '0',
            'worst_raster_ms': '50',
          }),
        ).called(1);
      });

      test('triggers on raster duration exceeding threshold', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 1),
        )..handleTimings([_frameTiming(rasterMs: 17)]);

        verify(
          () => platform.logInfo('slow-frames', {
            'count': '1',
            'worst_build_ms': '0',
            'worst_raster_ms': '17',
          }),
        ).called(1);
      });
    });

    group('frozen frames', () {
      test('reports logWarning immediately for frozen build duration', () {
        detector.handleTimings([_frameTiming(buildMs: 701)]);

        verify(
          () => platform.logWarning(
            'frozen-frame',
            {'build_ms': '701', 'raster_ms': '0'},
          ),
        ).called(1);
      });

      test('reports logWarning for frame at exactly frozen threshold', () {
        detector.handleTimings([_frameTiming(buildMs: 700)]);

        verify(
          () => platform.logWarning(
            'frozen-frame',
            {'build_ms': '700', 'raster_ms': '0'},
          ),
        ).called(1);
      });

      test('reports logWarning immediately for frozen raster duration', () {
        detector.handleTimings([_frameTiming(rasterMs: 701)]);

        verify(
          () => platform.logWarning(
            'frozen-frame',
            {'build_ms': '0', 'raster_ms': '701'},
          ),
        ).called(1);
      });

      test('does not count frozen frames as slow frames', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 1),
        )..handleTimings([_frameTiming(buildMs: 701)]);

        verifyNever(() => platform.logInfo(any(), any()));
      });

      test('reports each frozen frame independently', () {
        detector
          ..handleTimings([_frameTiming(buildMs: 800)])
          ..handleTimings([_frameTiming(buildMs: 900)]);

        verify(() => platform.logWarning('frozen-frame', any())).called(2);
      });
    });

    group('mixed frames in a single batch', () {
      test('handles slow and frozen frames in the same callback', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 1),
        )..handleTimings([
            _frameTiming(buildMs: 20),
            _frameTiming(buildMs: 800),
          ]);

        verify(() => platform.logInfo('slow-frames', any())).called(1);
        verify(() => platform.logWarning('frozen-frame', any())).called(1);
      });
    });

    group('route correlation', () {
      test('includes route in slow-frames log when route is set', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 1),
        )
          ..currentRoute = '/home'
          ..handleTimings([_frameTiming(buildMs: 20)]);

        verify(
          () => platform.logInfo('slow-frames', {
            'count': '1',
            'worst_build_ms': '20',
            'worst_raster_ms': '0',
            'route': '/home',
          }),
        ).called(1);
      });

      test('includes route in frozen-frame log when route is set', () {
        detector
          ..currentRoute = '/detail'
          ..handleTimings([_frameTiming(buildMs: 800)]);

        verify(
          () => platform.logWarning(
            'frozen-frame',
            {'build_ms': '800', 'raster_ms': '0', 'route': '/detail'},
          ),
        ).called(1);
      });

      test('omits route key when no route has been set', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 1),
        )..handleTimings([_frameTiming(buildMs: 20)]);

        verify(
          () => platform.logInfo('slow-frames', {
            'count': '1',
            'worst_build_ms': '20',
            'worst_raster_ms': '0',
          }),
        ).called(1);
      });

      test('updates route between batches', () {
        detector = EmbraceFrameDetector(
          config: const EmbraceFrameDetectionConfig(slowFrameBatchSize: 1),
        )
          ..currentRoute = '/first'
          ..handleTimings([_frameTiming(buildMs: 20)])
          ..currentRoute = '/second'
          ..handleTimings([_frameTiming(buildMs: 20)]);

        verifyInOrder([
          () => platform.logInfo('slow-frames', {
                'count': '1',
                'worst_build_ms': '20',
                'worst_raster_ms': '0',
                'route': '/first',
              }),
          () => platform.logInfo('slow-frames', {
                'count': '1',
                'worst_build_ms': '20',
                'worst_raster_ms': '0',
                'route': '/second',
              }),
        ]);
      });
    });

    group('stop', () {
      test('stop does not throw', () {
        detector
          ..start()
          ..stop();
      });
    });
  });
}
