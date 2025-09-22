import 'package:embrace/embrace.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

class FakeRoute extends Fake implements Route<dynamic> {
  FakeRoute(this.settings);

  @override
  final RouteSettings settings;
}

void main() {
  late EmbraceNavigationObserver observer;
  late MockEmbracePlatform platform;

  setUp(() {
    observer = EmbraceNavigationObserver();
    platform = MockEmbracePlatform();
    EmbracePlatform.instance = platform;
  });
  group('EmbraceNavigationObserver', () {
    group('didPush', () {
      test('ends previous view ', () {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute = FakeRoute(
          const RouteSettings(name: 'previousRoute'),
        );
        observer.didPush(route, previousRoute);

        verify(() => platform.endView('previousRoute')).called(1);
      });

      test('starts new view', () {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute = FakeRoute(
          const RouteSettings(name: 'previousRoute'),
        );
        observer.didPush(route, previousRoute);

        verify(() => platform.startView('route')).called(1);
      });

      test('does not end new view if previousRoute is empty', () {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPush(route, null);
        verifyNever(() => platform.endView(any()));
      });
      test('can use custom name for starting view '
          'when using routeSettingsExtractor', () {
        final observer = EmbraceNavigationObserver(
          routeSettingsExtractor: (route) {
            return RouteSettings(name: route.settings.name?.toUpperCase());
          },
        );
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPush(route, null);
        verify(() => platform.startView('ROUTE')).called(1);
      });

      test('can use custom name for ending view '
          'when using routeSettingsExtractor', () {
        final observer = EmbraceNavigationObserver(
          routeSettingsExtractor: (route) {
            return RouteSettings(name: route.settings.name?.toUpperCase());
          },
        );
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute = FakeRoute(
          const RouteSettings(name: 'previousRoute'),
        );
        observer.didPush(route, previousRoute);
        verify(() => platform.endView('PREVIOUSROUTE')).called(1);
      });
    });
    group('didPop', () {
      test('start back previous view ', () {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute = FakeRoute(
          const RouteSettings(name: 'previousRoute'),
        );
        observer.didPop(route, previousRoute);

        verify(() => platform.startView('previousRoute')).called(1);
      });

      test('ends new view', () {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute = FakeRoute(
          const RouteSettings(name: 'previousRoute'),
        );
        observer.didPop(route, previousRoute);

        verify(() => platform.endView('route')).called(1);
      });

      test('does not start back previous view if previousRoute is empty', () {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPop(route, null);
        verifyNever(() => platform.startView(any()));
      });

      test('can use custom name for ending view '
          'when using routeSettingsExtractor', () {
        final observer = EmbraceNavigationObserver(
          routeSettingsExtractor: (route) {
            return RouteSettings(name: route.settings.name?.toUpperCase());
          },
        );
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPop(route, null);
        verify(() => platform.endView('ROUTE')).called(1);
      });

      test('can use custom name for starting view '
          'when using routeSettingsExtractor', () {
        final observer = EmbraceNavigationObserver(
          routeSettingsExtractor: (route) {
            return RouteSettings(name: route.settings.name?.toUpperCase());
          },
        );
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute = FakeRoute(
          const RouteSettings(name: 'previousRoute'),
        );
        observer.didPop(route, previousRoute);
        verify(() => platform.startView('PREVIOUSROUTE')).called(1);
      });
    });
  });
}
