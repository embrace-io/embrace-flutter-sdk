import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A function that extracts the settings from a route
typedef EmbraceRouteSettingsExtractor = RouteSettings? Function(
  Route<dynamic> route,
);

/// {@template embrace_navigation_observer}
/// A [NavigatorObserver] that automatically tracks app navigation.
/// Records an OTel span for each named route transition, from push/replace
/// until the transition animation completes.
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
  }) : routeSettingsExtractor = routeSettingsExtractor ?? _defaultExtractor;

  /// A function that returns the settings from a given route
  ///
  /// If null, it returns the route default settings.
  /// This can be used to modify the route names that are tracked by Embrace,
  /// or return null to avoid tracking a specific view
  final EmbraceRouteSettingsExtractor? routeSettingsExtractor;

  static RouteSettings? _defaultExtractor(Route<dynamic> route) {
    return route.settings;
  }

  void _startTtiSpan(String routeName) {
    final startTimeMs = DateTime.now().millisecondsSinceEpoch;
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

  void _startTransitionSpan(Route<dynamic> route, String routeName) {
    final startTimeMs = DateTime.now().millisecondsSinceEpoch;
    final animation = route is TransitionRoute ? route.animation : null;
    EmbraceSpan? pendingSpan;
    var stopped = false;

    void stopSpan() {
      if (stopped) return;
      stopped = true;
      pendingSpan?.stop(endTimeMs: DateTime.now().millisecondsSinceEpoch);
    }

    Embrace.instance.startSpan(routeName, startTimeMs: startTimeMs).then(
      (span) {
        if (span == null) return;
        span.addAttribute('emb.type', 'view');
        pendingSpan = span;
        if (stopped) {
          span.stop(endTimeMs: DateTime.now().millisecondsSinceEpoch);
        }
      },
      onError: (_, __) {},
    );

    if (animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed) {
      stopSpan();
      return;
    }

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animation.removeStatusListener(listener);
        stopSpan();
      }
    }

    animation.addStatusListener(listener);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = routeSettingsExtractor?.call(route)?.name;
    if (routeName != null) {
      _startTtiSpan(routeName);
      _startTransitionSpan(route, routeName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute == null) return;
    final routeName = routeSettingsExtractor?.call(newRoute)?.name;
    if (routeName != null) {
      _startTtiSpan(routeName);
      _startTransitionSpan(newRoute, routeName);
    }
  }
}
