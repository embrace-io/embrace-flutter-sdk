import 'package:embrace/src/embrace_hang_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbraceHangDetectionConfig', () {
    test('has expected defaults', () {
      const config = EmbraceHangDetectionConfig();

      expect(config.pingInterval, const Duration(milliseconds: 1000));
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
}
