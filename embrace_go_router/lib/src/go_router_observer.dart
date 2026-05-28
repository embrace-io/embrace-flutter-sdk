import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// {@template embrace_go_router_observer}
/// A [NavigatorObserver] that automatically tracks app navigation for apps
/// using go_router. Registers in Embrace when a view starts or stops by
/// listening when a route is pushed or popped.
///
/// ## Simple apps (no `StatefulShellRoute`)
///
/// Pass the observer to `GoRouter.observers`. The view name is taken from
/// [RouteSettings.name], which for go_router is the route path.
///
/// ```dart
/// import 'package:go_router/go_router.dart';
/// import 'package:embrace_go_router/embrace_go_router.dart';
///
/// final router = GoRouter(
///   observers: [EmbraceGoRouterObserver()],
///   routes: [...],
/// );
/// ```
///
/// ## Apps using `StatefulShellRoute`
///
/// Pass the [GoRouter] instance directly. This wires into go_router's
/// `routeInformationProvider`, capturing every route change including those
/// in sub-navigators that a [NavigatorObserver] would miss. Do **not** also
/// add this observer to `GoRouter.observers` in this mode.
///
/// ```dart
/// import 'package:go_router/go_router.dart';
/// import 'package:embrace_go_router/embrace_go_router.dart';
///
/// final _router = GoRouter(routes: [...]);
/// late final _observer = EmbraceGoRouterObserver(router: _router);
///
/// @override
/// void dispose() {
///   _observer.dispose();
///   super.dispose();
/// }
/// ```
///
/// The [routeSettingsExtractor] parameter only applies when no `router` is
/// provided (i.e. [NavigatorObserver] mode).
/// {@endtemplate}
class EmbraceGoRouterObserver extends NavigatorObserver {
  /// {@macro embrace_go_router_observer}
  EmbraceGoRouterObserver({
    GoRouter? router,
    EmbraceRouteSettingsExtractor? routeSettingsExtractor,
  })  : _router = router,
        routeSettingsExtractor = routeSettingsExtractor ?? _defaultExtractor {
    if (router != null) {
      router.routeInformationProvider.addListener(_onRouteChanged);
      _reportCurrentRoute();
    }
  }

  final GoRouter? _router;
  String? _currentView;
  bool _disposed = false;

  // State span fields — delegate mode only.
  EmbraceSpan? _stateSpan;
  int _transitionCount = 0;
  final List<String> _pendingTransitions = [];

  /// A function that returns the settings from a given route.
  ///
  /// Only used in [NavigatorObserver] mode (when no `router` is provided).
  /// If null, returns the route's default settings. Can be used to customise
  /// the route names tracked by Embrace, or return null to skip tracking a
  /// specific route.
  final EmbraceRouteSettingsExtractor? routeSettingsExtractor;

  static RouteSettings? _defaultExtractor(Route<dynamic> route) {
    return route.settings;
  }

  void _reportCurrentRoute() {
    final router = _router;
    if (router == null) return;
    final name = router.routeInformationProvider.value.uri.path;
    if (name.isEmpty) return;
    _currentView = name;
    _initStateSpan(name);
    _startTtiSpan(name);
  }

  void _initStateSpan(String initialRoute) {
    Embrace.instance.startSpan('emb-state-screen-flutter-automatic').then(
      (span) {
        if (span == null) return;
        if (_disposed) {
          span.stop();
          return;
        }
        _stateSpan = span;
        span
          ..addAttribute('emb.type', 'state')
          ..addAttribute('emb.state.initial_value', initialRoute);
        for (final route in _pendingTransitions) {
          span.addEvent(
            'transition',
            attributes: {'emb.state.new_value': route},
          );
        }
        _pendingTransitions.clear();
      },
      onError: (_, __) {},
    );
  }

  void _recordTransition(String routeName) {
    _transitionCount++;
    final span = _stateSpan;
    if (span != null) {
      span.addEvent(
        'transition',
        attributes: {'emb.state.new_value': routeName},
      );
    } else {
      _pendingTransitions.add(routeName);
    }
  }

  void _onRouteChanged() {
    final router = _router;
    if (router == null) return;
    final name = router.routeInformationProvider.value.uri.path;
    if (name.isEmpty || name == _currentView) return;
    _currentView = name;
    _recordTransition(name);
    _startTtiSpan(name);
  }

  /// Removes the listener from the [GoRouter] and stops the state span.
  ///
  /// Must be called when the observer is no longer needed, to avoid leaking
  /// the listener. Only required when `router` was provided at construction.
  void dispose() {
    _disposed = true;
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    final span = _stateSpan;
    if (span != null) {
      span
          .addAttribute('emb.state.transition_count', '$_transitionCount')
          .then((_) => span.stop(), onError: (_, __) {});
      _stateSpan = null;
    }
    _currentView = null;
    _transitionCount = 0;
    _pendingTransitions.clear();
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
    if (_router != null) return;
    _updateView(route, previousRoute);
    final routeName = routeSettingsExtractor?.call(route)?.name;
    if (routeName != null) {
      _startTtiSpan(routeName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_router != null) return;
    _updateView(newRoute, oldRoute);
    final routeName =
        newRoute != null ? routeSettingsExtractor?.call(newRoute)?.name : null;
    if (routeName != null) {
      _startTtiSpan(routeName);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_router != null) return;
    _updateView(previousRoute, route);
  }
}
