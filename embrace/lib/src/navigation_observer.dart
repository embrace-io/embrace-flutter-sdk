import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:embrace/src/embrace_startup_tracker.dart';
import 'package:embrace/src/pointer_input_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A function that extracts the settings from a route
typedef EmbraceRouteSettingsExtractor = RouteSettings? Function(
  Route<dynamic> route,
);

/// Configuration for the screen-load span timing recorded by
/// [EmbraceNavigationObserver].
class EmbraceScreenLoadConfig {
  /// Creates a screen-load span timing configuration.
  const EmbraceScreenLoadConfig({
    this.recencyThreshold = const Duration(seconds: 1),
  });

  /// How old a recorded touch can be and still count as the input that
  /// triggered a route transition. If the last touch is older than this,
  /// the span falls back to using the route-push time as its start.
  final Duration recencyThreshold;
}

/// {@template embrace_navigation_observer}
/// A [NavigatorObserver] that automatically tracks app navigation
/// This class registers in Embrace when a view starts or stops by listening
/// when a route is pushed or popped.
///
/// [EmbraceNavigationObserver] should be added to the [navigationObserver](https://api.flutter.dev/flutter/material/MaterialApp/navigatorObservers.html)
/// of [MaterialApp] or your main [Navigator].
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:embrace/embrace.dart';
///
/// MaterialApp(
///   navigatorObservers: [
///     EmbraceNavigatorObserver(),
///   ],
///   // ...
/// )
/// ```
///
/// By default the view name is the same as the route name from its settings,
/// but it can be modified by using a custom name extractor in
/// [routeSettingsExtractor]
///
/// ```dart
/// MaterialPageRoute(settings: RouteSettings(name: 'FirstPage'))
/// ```
/// {@endtemplate}
class EmbraceNavigationObserver extends RouteObserver<ModalRoute<dynamic>> {
  /// {@macro embrace_navigation_observer}
  EmbraceNavigationObserver({
    EmbraceRouteSettingsExtractor? routeSettingsExtractor,
    this.screenLoadConfig = const EmbraceScreenLoadConfig(),
  }) : routeSettingsExtractor = routeSettingsExtractor ?? _defaultExtractor;

  /// A function that returns the settings from a given route
  ///
  /// If null, it returns the route default settings.
  /// This can be used to modify the route names that are tracked by Embrace,
  /// or return null to avoid tracking a specific view
  final EmbraceRouteSettingsExtractor? routeSettingsExtractor;

  /// Configuration for the screen-load span timing.
  final EmbraceScreenLoadConfig screenLoadConfig;

  static RouteSettings? _defaultExtractor(Route<dynamic> route) {
    return route.settings;
  }

  static bool _ttiSpanStarted = false;

  /// Resets the one-shot TTI span state. Intended for use in test
  /// `tearDown`.
  @visibleForTesting
  static void resetTtiSpanForTesting() {
    _ttiSpanStarted = false;
  }

  void _startScreenLoadSpan(String routeName) {
    final startTimeMs = EmbracePointerInputTracker.resolveStartTimeMs(
      DateTime.now(),
      screenLoadConfig.recencyThreshold,
    );
    int? endTimeMs;
    EmbraceSpan? pendingSpan;

    void tryStop() {
      final span = pendingSpan;
      final endMs = endTimeMs;
      if (span != null && endMs != null) {
        span.stop(endTimeMs: endMs);
      }
    }

    Embrace.instance
        .startSpan(
      routeName,
      startTimeMs: startTimeMs,
    )
        .then(
      (span) {
        pendingSpan = span;
        span?.addAttribute('emb.type', 'view');
        tryStop();
      },
      onError: (_, __) {},
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      endTimeMs = DateTime.now().millisecondsSinceEpoch;
      tryStop();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _startTtiSpan(String routeName) {
    if (_ttiSpanStarted) return;
    _ttiSpanStarted = true;

    final startTimeMs = EmbraceStartupTracker.startEpochMs ??
        DateTime.now().millisecondsSinceEpoch;
    int? endTimeMs;
    EmbraceSpan? pendingSpan;

    void tryStop() {
      final span = pendingSpan;
      final endMs = endTimeMs;
      if (span != null && endMs != null) {
        span
          ..addAttribute('route', routeName)
          ..stop(endTimeMs: endMs);
      }
    }

    Embrace.instance
        .startSpan(
      'emb-time-to-interactive-flutter',
      startTimeMs: startTimeMs,
    )
        .then(
      (span) {
        pendingSpan = span;
        tryStop();
      },
      onError: (_, __) {},
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      endTimeMs = DateTime.now().millisecondsSinceEpoch;
      tryStop();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _updateView(Route<dynamic>? newRoute, Route<dynamic>? oldRoute) {
    if (oldRoute != null) {
      final settings = routeSettingsExtractor?.call(oldRoute);
      final name = settings?.name;
      if (name != null) {
        Embrace.instance.endView(name);
      }
    }
    if (newRoute != null) {
      final settings = routeSettingsExtractor?.call(newRoute);
      final name = settings?.name;
      if (name != null) {
        Embrace.instance.startView(name);
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateView(route, previousRoute);
    final routeName = routeSettingsExtractor?.call(route)?.name;
    if (routeName != null) {
      _startTtiSpan(routeName);
      _startScreenLoadSpan(routeName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateView(newRoute, oldRoute);
    final routeName =
        newRoute != null ? routeSettingsExtractor?.call(newRoute)?.name : null;
    if (routeName != null) {
      _startTtiSpan(routeName);
      _startScreenLoadSpan(routeName);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateView(previousRoute, route);
  }
}
