import 'package:embrace/src/embrace_hang_detector.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'observer_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmbraceHangDetectionConfig', () {
    test('has expected defaults', () {
      const config = EmbraceHangDetectionConfig();

      expect(config.tickInterval, const Duration(milliseconds: 200));
      expect(config.hangThreshold, const Duration(milliseconds: 700));
    });

    test('accepts custom values', () {
      const config = EmbraceHangDetectionConfig(
        tickInterval: Duration(milliseconds: 500),
        hangThreshold: Duration(milliseconds: 300),
      );

      expect(config.tickInterval, const Duration(milliseconds: 500));
      expect(config.hangThreshold, const Duration(milliseconds: 300));
    });
  });

  group('EmbraceHangTracker', () {
    test('onTick returns null when the gap is below the hang threshold', () {
      final start = DateTime(2026);
      final tracker = EmbraceHangTracker(
        const Duration(milliseconds: 700),
        initialGoodTime: start,
      );

      final resolved =
          tracker.onTick(start.add(const Duration(milliseconds: 200)));

      expect(resolved, isNull);
    });

    test('records a hang once the threshold is crossed', () {
      final start = DateTime(2026);
      final tracker = EmbraceHangTracker(
        const Duration(milliseconds: 700),
        initialGoodTime: start,
      )
        ..onTick(start.add(const Duration(milliseconds: 200)))
        ..onTick(start.add(const Duration(milliseconds: 400)));

      final tickTime = start.add(const Duration(milliseconds: 1200));
      final resolved = tracker.onTick(tickTime);

      expect(resolved, isNotNull);
      expect(resolved!.start, start.add(const Duration(milliseconds: 400)));
      expect(resolved.end, tickTime);
    });

    test('does not re-report once a hang has been resolved', () {
      final start = DateTime(2026);
      final tracker = EmbraceHangTracker(
        const Duration(milliseconds: 700),
        initialGoodTime: start,
      );

      final firstHangTick = start.add(const Duration(milliseconds: 900));
      tracker.onTick(firstHangTick);

      final secondTickTime =
          firstHangTick.add(const Duration(milliseconds: 200));
      final resolved = tracker.onTick(secondTickTime);

      expect(resolved, isNull);
    });
  });

  group('EmbraceHangDetector', () {
    late MockEmbracePlatform platform;

    setUp(() {
      platform = MockEmbracePlatform();
      EmbracePlatform.instance = platform;
      when(
        () => platform.recordCompletedSpan(
          any(),
          any(),
          any(),
          attributes: any(named: 'attributes'),
        ),
      ).thenAnswer((_) async => true);
    });

    test('start and stop do not throw', () async {
      final detector = EmbraceHangDetector();

      await detector.start();
      expect(detector.stop, returnsNormally);
    });

    test('records a completed span when a hang is reported', () async {
      final start = DateTime(2026);
      final detector = EmbraceHangDetector();
      await detector.start();
      detector
        ..handleTick(start)
        ..handleTick(start.add(const Duration(milliseconds: 200)))
        ..handleTick(start.add(const Duration(milliseconds: 900)))
        ..stop();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => platform.recordCompletedSpan(
          'emb-dart-isolate-hang',
          start.add(const Duration(milliseconds: 200)).millisecondsSinceEpoch,
          start.add(const Duration(milliseconds: 900)).millisecondsSinceEpoch,
          attributes: {'duration_ms': '700'},
        ),
      ).called(1);
    });

    test('ignores ticks with no active tracker', () {
      final detector = EmbraceHangDetector();

      expect(() => detector.handleTick(DateTime.now()), returnsNormally);
      verifyNever(() => platform.recordCompletedSpan(any(), any(), any()));
    });

    test('stops monitoring when the app is backgrounded', () async {
      final detector = EmbraceHangDetector();
      await detector.start();
      expect(detector.isMonitoring, isTrue);

      detector.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(detector.isMonitoring, isFalse);
      detector.stop();
    });

    test('restarts monitoring when the app returns to the foreground',
        () async {
      final detector = EmbraceHangDetector();
      await detector.start();
      detector
        ..didChangeAppLifecycleState(AppLifecycleState.paused)
        ..didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(detector.isMonitoring, isTrue);
      detector.stop();
    });

    test('ignores transient lifecycle states', () async {
      final detector = EmbraceHangDetector();
      await detector.start();

      detector
        ..didChangeAppLifecycleState(AppLifecycleState.inactive)
        ..didChangeAppLifecycleState(AppLifecycleState.hidden)
        ..didChangeAppLifecycleState(AppLifecycleState.detached);

      expect(detector.isMonitoring, isTrue);
      detector.stop();
    });

    group('stopActiveHangDetector', () {
      test('does nothing when no detector is active', () {
        expect(stopActiveHangDetector, returnsNormally);
      });

      test('stops the active detector', () async {
        final detector = EmbraceHangDetector();
        await detector.start();
        expect(detector.isMonitoring, isTrue);

        stopActiveHangDetector();

        expect(detector.isMonitoring, isFalse);
      });
    });
  });
}
