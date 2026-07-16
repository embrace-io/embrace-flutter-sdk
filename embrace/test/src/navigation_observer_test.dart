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
      late MockEmbraceSpan screenLoadSpanStub;

      setUpAll(() {
        registerFallbackValue('');
      });

      setUp(() {
        mockEmbrace = MockEmbrace();
        mockSpan = MockEmbraceSpan();
        screenLoadSpanStub = MockEmbraceSpan();
        // ignore: invalid_use_of_visible_for_testing_member
        debugEmbraceOverride = mockEmbrace;
        when(() => mockEmbrace.startView(any())).thenAnswer((_) {});
        when(() => mockEmbrace.endView(any())).thenAnswer((_) {});
        // didPush/didReplace also start a screen-load span (see the
        // 'screen load spans' group below) — stub a catch-all for it here
        // too so it doesn't throw, without affecting this group's TTI
        // assertions. Registered before the exact TTI stub below, which
        // overrides it for that specific call.
        when(
          () => mockEmbrace.startSpan(
            any(),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) => Future.value(screenLoadSpanStub));
        when(
          () => mockEmbrace.startSpan(
            'emb-time-to-interactive-flutter',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) => Future.value(mockSpan));
        when(() => mockSpan.addAttribute(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSpan.stop(endTimeMs: any(named: 'endTimeMs')))
            .thenAnswer((_) async => true);
        when(() => screenLoadSpanStub.addAttribute(any(), any()))
            .thenAnswer((_) async => true);
        when(() => screenLoadSpanStub.stop(endTimeMs: any(named: 'endTimeMs')))
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
            'emb-time-to-interactive-flutter',
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
            'emb-time-to-interactive-flutter',
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

    group('screen load spans', () {
      late MockEmbrace mockEmbrace;
      late MockEmbraceSpan screenLoadSpan;
      late MockEmbraceSpan ttiSpan;

      setUpAll(() {
        registerFallbackValue('');
      });

      setUp(() {
        mockEmbrace = MockEmbrace();
        screenLoadSpan = MockEmbraceSpan();
        ttiSpan = MockEmbraceSpan();
        // ignore: invalid_use_of_visible_for_testing_member
        debugEmbraceOverride = mockEmbrace;
        when(() => mockEmbrace.startView(any())).thenAnswer((_) {});
        when(() => mockEmbrace.endView(any())).thenAnswer((_) {});
        // didPush/didReplace also start a TTI span (see the 'TTI spans'
        // group above) — stub a catch-all for it here so it doesn't throw,
        // without this group's tests needing to know its name. Each test
        // below overrides this for the specific route name it exercises.
        when(
          () => mockEmbrace.startSpan(
            any(),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) => Future.value(ttiSpan));
        when(() => ttiSpan.addAttribute(any(), any()))
            .thenAnswer((_) async => true);
        when(() => ttiSpan.stop(endTimeMs: any(named: 'endTimeMs')))
            .thenAnswer((_) async => true);
        when(() => screenLoadSpan.addAttribute(any(), any()))
            .thenAnswer((_) async => true);
        when(() => screenLoadSpan.stop(endTimeMs: any(named: 'endTimeMs')))
            .thenAnswer((_) async => true);
      });

      void stubScreenLoadSpan(String routeName) {
        when(
          () => mockEmbrace.startSpan(
            routeName,
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) => Future.value(screenLoadSpan));
      }

      tearDown(() {
        // ignore: invalid_use_of_visible_for_testing_member
        debugEmbraceOverride = null;
      });

      testWidgets('starts a span named after the route on push',
          (tester) async {
        stubScreenLoadSpan('route');
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPush(route, null);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'route',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => screenLoadSpan.addAttribute('emb.type', 'view'))
            .called(1);
        verify(
          () => screenLoadSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('span name uses name from routeSettingsExtractor',
          (tester) async {
        stubScreenLoadSpan('ROUTE');
        final observer = EmbraceNavigationObserver(
          routeSettingsExtractor: (route) =>
              RouteSettings(name: route.settings.name?.toUpperCase()),
        );
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPush(route, null);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'ROUTE',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
      });

      testWidgets('does not start a span when route name is null',
          (tester) async {
        final route = FakeRoute(const RouteSettings());
        observer.didPush(route, null);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });

      testWidgets('starts a span on replace', (tester) async {
        stubScreenLoadSpan('route');
        final newRoute = FakeRoute(const RouteSettings(name: 'route'));
        observer.didReplace(newRoute: newRoute);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'route',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => screenLoadSpan.addAttribute('emb.type', 'view'))
            .called(1);
        verify(
          () => screenLoadSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('does not start a span when newRoute is null on replace',
          (tester) async {
        final oldRoute = FakeRoute(const RouteSettings(name: 'route'));
        observer.didReplace(oldRoute: oldRoute);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });

      testWidgets('does not start a span on pop', (tester) async {
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
