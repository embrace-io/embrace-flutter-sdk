import 'package:embrace/embrace.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'observer_test_helpers.dart';

void main() {
  late EmbraceNavigationObserver observer;

  setUp(() {
    observer = EmbraceNavigationObserver();
  });

  group('EmbraceNavigationObserver', () {
    group('view tracking', () {
      late MockEmbracePlatform platform;

      setUp(() {
        platform = MockEmbracePlatform();
        EmbracePlatform.instance = platform;
      });

      group('didPush', () {
        test('ends previous view', () {
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

        test('does not end view if previousRoute is null', () {
          final route = FakeRoute(const RouteSettings(name: 'route'));
          observer.didPush(route, null);
          verifyNever(() => platform.endView(any()));
        });

        test('can use custom name for starting view via routeSettingsExtractor',
            () {
          final observer = EmbraceNavigationObserver(
            routeSettingsExtractor: (route) =>
                RouteSettings(name: route.settings.name?.toUpperCase()),
          );
          final route = FakeRoute(const RouteSettings(name: 'route'));
          observer.didPush(route, null);
          verify(() => platform.startView('ROUTE')).called(1);
        });

        test('can use custom name for ending view via routeSettingsExtractor',
            () {
          final observer = EmbraceNavigationObserver(
            routeSettingsExtractor: (route) =>
                RouteSettings(name: route.settings.name?.toUpperCase()),
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
        test('starts back previous view', () {
          final route = FakeRoute(const RouteSettings(name: 'route'));
          final previousRoute = FakeRoute(
            const RouteSettings(name: 'previousRoute'),
          );
          observer.didPop(route, previousRoute);

          verify(() => platform.startView('previousRoute')).called(1);
        });

        test('ends popped view', () {
          final route = FakeRoute(const RouteSettings(name: 'route'));
          final previousRoute = FakeRoute(
            const RouteSettings(name: 'previousRoute'),
          );
          observer.didPop(route, previousRoute);

          verify(() => platform.endView('route')).called(1);
        });

        test('does not start view if previousRoute is null', () {
          final route = FakeRoute(const RouteSettings(name: 'route'));
          observer.didPop(route, null);
          verifyNever(() => platform.startView(any()));
        });

        test('can use custom name for ending view via routeSettingsExtractor',
            () {
          final observer = EmbraceNavigationObserver(
            routeSettingsExtractor: (route) =>
                RouteSettings(name: route.settings.name?.toUpperCase()),
          );
          final route = FakeRoute(const RouteSettings(name: 'route'));
          observer.didPop(route, null);
          verify(() => platform.endView('ROUTE')).called(1);
        });

        test('can use custom name for starting view via routeSettingsExtractor',
            () {
          final observer = EmbraceNavigationObserver(
            routeSettingsExtractor: (route) =>
                RouteSettings(name: route.settings.name?.toUpperCase()),
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

    group('TTI spans', () {
      late MockEmbrace mockEmbrace;
      late MockEmbraceSpan mockSpan;

      setUpAll(() {
        registerFallbackValue('');
      });

      setUp(() {
        mockEmbrace = MockEmbrace();
        mockSpan = MockEmbraceSpan();
        // ignore: invalid_use_of_visible_for_testing_member
        debugEmbraceOverride = mockEmbrace;
        when(() => mockEmbrace.startView(any())).thenAnswer((_) {});
        when(() => mockEmbrace.endView(any())).thenAnswer((_) {});
        when(
          () => mockEmbrace.startSpan(
            'emb-flutter-time-to-interactive',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) => Future.value(mockSpan));
        when(() => mockSpan.addAttribute(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSpan.stop(endTimeMs: any(named: 'endTimeMs')))
            .thenAnswer((_) async => true);
      });

      tearDown(() {
        // ignore: invalid_use_of_visible_for_testing_member
        debugEmbraceOverride = null;
      });

      testWidgets('starts a TTI span on push', (tester) async {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPush(route, null);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'emb-flutter-time-to-interactive',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => mockSpan.addAttribute('route', 'route')).called(1);
        verify(
          () => mockSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('TTI span uses name from routeSettingsExtractor',
          (tester) async {
        final observer = EmbraceNavigationObserver(
          routeSettingsExtractor: (route) =>
              RouteSettings(name: route.settings.name?.toUpperCase()),
        );
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPush(route, null);
        await tester.pump();

        verify(() => mockSpan.addAttribute('route', 'ROUTE')).called(1);
      });

      testWidgets('does not start a TTI span when route name is null',
          (tester) async {
        final route = FakeRoute(const RouteSettings());
        observer.didPush(route, null);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });

      testWidgets('starts a TTI span on replace', (tester) async {
        final newRoute = FakeRoute(const RouteSettings(name: 'route'));
        observer.didReplace(newRoute: newRoute);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'emb-flutter-time-to-interactive',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => mockSpan.addAttribute('route', 'route')).called(1);
        verify(
          () => mockSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('does not start a TTI span when newRoute is null on replace',
          (tester) async {
        final oldRoute = FakeRoute(const RouteSettings(name: 'route'));
        observer.didReplace(oldRoute: oldRoute);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });

      testWidgets('does not start a TTI span on pop', (tester) async {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute =
            FakeRoute(const RouteSettings(name: 'previousRoute'));
        observer.didPop(route, previousRoute);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });
    });
  });
}
