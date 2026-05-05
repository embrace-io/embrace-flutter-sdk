import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// {@template embrace_go_router_observer}
/// A [NavigatorObserver] that automatically tracks app navigation for apps
/// using go_router. Registers in Embrace when a view starts or stops by
/// listening when a route is pushed or popped.
///
/// [EmbraceGoRouterObserver] should be added to the [observers](https://pub.dev/documentation/go_router/latest/go_router/GoRouter/observers.html)
/// of your GoRouter instance.
///
/// ```dart
/// import 'package:go_router/go_router.dart';
/// import 'package:embrace/embrace.dart';
///
/// final router = GoRouter(
///   observers: [EmbraceGoRouterObserver()],
///   routes: [...],
/// );
/// ```
///
/// By default the view name is taken from [RouteSettings.name], which for
/// go_router is the route path. It can be overridden with
/// [routeSettingsExtractor].
/// {@endtemplate}
class EmbraceGoRouterObserver extends NavigatorObserver {
  /// {@macro embrace_go_router_observer}
  EmbraceGoRouterObserver({
    EmbraceRouteSettingsExtractor? routeSettingsExtractor,
  }) : routeSettingsExtractor = routeSettingsExtractor ?? _defaultExtractor;

  /// A function that returns the settings from a given route.
  ///
  /// If null, returns the route's default settings. Can be used to customise
  /// the route names tracked by Embrace, or return null to skip tracking a
  /// specific route.
  final EmbraceRouteSettingsExtractor? routeSettingsExtractor;

  static RouteSettings? _defaultExtractor(Route<dynamic> route) {
    return route.settings;
  }

  void _startTtiSpan(String routeName) {
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

    Embrace.instance.startSpan('emb-flutter-time-to-interactive').then(
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
    _updateView(route, previousRoute);
    final routeName = routeSettingsExtractor?.call(route)?.name;
    if (routeName != null) {
      _startTtiSpan(routeName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updateView(newRoute, oldRoute);
    final routeName =
        newRoute != null ? routeSettingsExtractor?.call(newRoute)?.name : null;
    if (routeName != null) {
      _startTtiSpan(routeName);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateView(previousRoute, route);
  }
}
