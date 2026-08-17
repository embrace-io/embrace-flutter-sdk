import 'package:embrace/src/pointer_input_tracker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(EmbracePointerInputTracker.resetForTesting);

  group('EmbracePointerInputTracker', () {
    group('init', () {
      testWidgets('can be called more than once without throwing',
          (tester) async {
        expect(EmbracePointerInputTracker.init, returnsNormally);
        expect(EmbracePointerInputTracker.init, returnsNormally);
      });

      testWidgets('captures PointerDownEvent dispatched via the global route',
          (tester) async {
        EmbracePointerInputTracker.init();

        GestureBinding.instance.pointerRouter.route(const PointerDownEvent());

        final pushTime = DateTime.now().add(const Duration(milliseconds: 1));
        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, isNot(pushTime.millisecondsSinceEpoch));
      });

      testWidgets('captures PointerUpEvent dispatched via the global route',
          (tester) async {
        EmbracePointerInputTracker.init();

        GestureBinding.instance.pointerRouter.route(const PointerUpEvent());

        final pushTime = DateTime.now().add(const Duration(milliseconds: 1));
        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, isNot(pushTime.millisecondsSinceEpoch));
      });

      testWidgets('ignores other pointer event types', (tester) async {
        EmbracePointerInputTracker.init();

        GestureBinding.instance.pointerRouter.route(const PointerMoveEvent());

        final pushTime = DateTime.now();
        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, pushTime.millisecondsSinceEpoch);
      });
    });

    group('resolveStartTimeMs', () {
      test('falls back to push time when no input was ever recorded', () {
        final pushTime = DateTime.now();

        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, pushTime.millisecondsSinceEpoch);
      });

      test('uses the recorded input time when within the recency threshold',
          () {
        final pushTime = DateTime.now();
        final inputTime = pushTime.subtract(const Duration(milliseconds: 500));
        EmbracePointerInputTracker.debugLastPointerEventTime = inputTime;

        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, inputTime.millisecondsSinceEpoch);
      });

      test('consumes the recorded input time so it cannot be reused', () {
        final pushTime = DateTime.now();
        final inputTime = pushTime.subtract(const Duration(milliseconds: 500));
        EmbracePointerInputTracker.debugLastPointerEventTime = inputTime;

        EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );
        final secondPushTime = pushTime.add(const Duration(milliseconds: 10));
        final secondStartTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          secondPushTime,
          const Duration(seconds: 1),
        );

        expect(secondStartTimeMs, secondPushTime.millisecondsSinceEpoch);
      });

      test('falls back to push time exactly at the recency threshold', () {
        final pushTime = DateTime.now();
        final inputTime = pushTime.subtract(const Duration(seconds: 1));
        EmbracePointerInputTracker.debugLastPointerEventTime = inputTime;

        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, inputTime.millisecondsSinceEpoch);
      });

      test('falls back to push time when input is older than the threshold',
          () {
        final pushTime = DateTime.now();
        final inputTime = pushTime.subtract(
          const Duration(seconds: 1, milliseconds: 1),
        );
        EmbracePointerInputTracker.debugLastPointerEventTime = inputTime;

        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, pushTime.millisecondsSinceEpoch);
      });

      test('falls back to push time when input is after push time', () {
        final pushTime = DateTime.now();
        final inputTime = pushTime.add(const Duration(milliseconds: 500));
        EmbracePointerInputTracker.debugLastPointerEventTime = inputTime;

        final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
          pushTime,
          const Duration(seconds: 1),
        );

        expect(startTimeMs, pushTime.millisecondsSinceEpoch);
      });
    });
  });
}
