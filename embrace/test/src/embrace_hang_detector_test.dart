import 'package:embrace/src/embrace_hang_detector.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'observer_test_helpers.dart';

void main() {
  group('EmbraceHangDetectionConfig', () {
    test('has expected defaults', () {
      const config = EmbraceHangDetectionConfig();

      expect(config.pingInterval, const Duration(milliseconds: 200));
      expect(config.hangThreshold, const Duration(milliseconds: 700));
    });

    test('accepts custom values', () {
      const config = EmbraceHangDetectionConfig(
        pingInterval: Duration(milliseconds: 500),
        hangThreshold: Duration(milliseconds: 300),
      );

      expect(config.pingInterval, const Duration(milliseconds: 500));
      expect(config.hangThreshold, const Duration(milliseconds: 300));
    });
  });

  group('EmbraceHangTracker', () {
    test('onEcho returns null when the gap is below the hang threshold', () {
      final start = DateTime(2026);
      final tracker = EmbraceHangTracker(
        const Duration(milliseconds: 700),
        initialGoodTime: start,
      );

      final resolved = (tracker
            ..onTick(start.add(const Duration(milliseconds: 200))))
          .onEcho(start.add(const Duration(milliseconds: 200)));

      expect(resolved, isNull);
    });

    test('records a hang once the threshold is crossed', () {
      final start = DateTime(2026);
      final tracker = EmbraceHangTracker(
        const Duration(milliseconds: 700),
        initialGoodTime: start,
      )
        ..onTick(start.add(const Duration(milliseconds: 200)))
        ..onTick(start.add(const Duration(milliseconds: 400)))
        ..onTick(start.add(const Duration(milliseconds: 800)));

      final echoTime = start.add(const Duration(milliseconds: 900));
      final resolved = tracker.onEcho(echoTime);

      expect(resolved, isNotNull);
      expect(resolved!.start, start);
      expect(resolved.end, echoTime);
    });

    test('does not re-report once a hang has been resolved', () {
      final start = DateTime(2026);
      final tracker = EmbraceHangTracker(
        const Duration(milliseconds: 700),
        initialGoodTime: start,
      );

      final firstEcho = start.add(const Duration(milliseconds: 900));
      (tracker..onTick(start.add(const Duration(milliseconds: 800))))
          .onEcho(firstEcho);

      final secondEchoTime = firstEcho.add(const Duration(milliseconds: 200));
      tracker.onTick(secondEchoTime);
      final resolved = tracker.onEcho(secondEchoTime);

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

    test('records a completed span when a hang is reported', () {
      EmbraceHangDetector().handleMonitorMessage([1000, 1700]);

      verify(
        () => platform.recordCompletedSpan(
          'emb-dart-isolate-hang',
          1000,
          1700,
          attributes: {'duration_ms': '700'},
        ),
      ).called(1);
    });

    test('ignores ping tokens and handshake messages', () {
      final detector = EmbraceHangDetector();

      expect(() => detector.handleMonitorMessage(1234), returnsNormally);
      verifyNever(() => platform.recordCompletedSpan(any(), any(), any()));
    });

    test('forwards uncaught errors from the monitor isolate', () {
      EmbraceHangDetector().handleMonitorError(['Exception: boom', '#0 main']);

      verify(
        () => platform.logDartError(
          '#0 main',
          'Exception: boom',
          any(),
          null,
          errorType: 'IsolateUncaughtError',
        ),
      ).called(1);
    });
  });
}
