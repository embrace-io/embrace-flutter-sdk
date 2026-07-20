import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Passively tracks the timestamp of the most recent user touch, so that
/// route transitions can be timed from the input that triggered them rather
/// than the moment the route was pushed.
///
/// Registers a global pointer route once at SDK startup, covering the whole
/// app with no widget-tree wrapping required.
class EmbracePointerInputTracker {
  static bool _initialized = false;
  static DateTime? _lastPointerEventTime;

  /// Registers the global pointer route. Safe to call multiple times — only
  /// the first call registers the handler.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointerEvent);
  }

  static void _onPointerEvent(PointerEvent event) {
    if (event is PointerDownEvent || event is PointerUpEvent) {
      _lastPointerEventTime = DateTime.now();
    }
  }

  /// Resolves the start time to use for a route transition span.
  ///
  /// If a qualifying touch was recorded within [recencyThreshold] of
  /// [pushTime], its timestamp is consumed (cleared) and returned so a
  /// later, unrelated push can't reuse it. Otherwise [pushTime] is returned.
  static int resolveStartTimeMs(DateTime pushTime, Duration recencyThreshold) {
    final lastEventTime = _lastPointerEventTime;
    if (lastEventTime == null) {
      return pushTime.millisecondsSinceEpoch;
    }

    final delta = pushTime.difference(lastEventTime);
    if (delta < Duration.zero || delta > recencyThreshold) {
      return pushTime.millisecondsSinceEpoch;
    }

    _lastPointerEventTime = null;
    return lastEventTime.millisecondsSinceEpoch;
  }

  /// The stored last-pointer-event time.
  @visibleForTesting
  static DateTime? get debugLastPointerEventTime => _lastPointerEventTime;

  /// Directly sets the stored last-pointer-event time, bypassing real
  /// gesture dispatch.
  @visibleForTesting
  static set debugLastPointerEventTime(DateTime? value) {
    _lastPointerEventTime = value;
  }

  /// Resets all static state, including unregistering the global route if
  /// [init] was called. Intended for use in test `tearDown`.
  @visibleForTesting
  static void resetForTesting() {
    if (_initialized) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _onPointerEvent,
      );
    }
    _initialized = false;
    _lastPointerEventTime = null;
  }
}
