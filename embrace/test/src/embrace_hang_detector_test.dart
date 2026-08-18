import 'package:embrace/src/embrace_hang_detector.dart';
import 'package:flutter_test/flutter_test.dart';

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
    test('start and stop do not throw', () async {
      final detector = EmbraceHangDetector();

      await detector.start();
      expect(detector.stop, returnsNormally);
    });
  });
}
