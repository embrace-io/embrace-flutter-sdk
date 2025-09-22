import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

/// A function that extracts the settings from a route
typedef EmbraceRouteSettingsExtractor =
    RouteSettings? Function(Route<dynamic> route);

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
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateView(newRoute, oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateView(previousRoute, route);
  }
}
