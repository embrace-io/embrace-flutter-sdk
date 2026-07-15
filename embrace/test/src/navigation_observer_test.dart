import 'package:embrace/embrace.dart';
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
        // Route transition spans are started alongside TTI spans on every
        // push/replace; stub them to a no-op span so they don't interfere
        // with the TTI-specific assertions below.
        when(
          () => mockEmbrace.startSpan(
            any(),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) => Future.value());
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

    group('route transition spans', () {
      late MockEmbrace mockEmbrace;
      late MockEmbraceSpan mockTransitionSpan;
      late MockEmbraceSpan mockTtiSpan;

      setUpAll(() {
        registerFallbackValue('');
      });

      setUp(() {
        mockEmbrace = MockEmbrace();
        mockTransitionSpan = MockEmbraceSpan();
        mockTtiSpan = MockEmbraceSpan();
        // ignore: invalid_use_of_visible_for_testing_member
        debugEmbraceOverride = mockEmbrace;
        when(
          () => mockEmbrace.startSpan(
            'emb-time-to-interactive-flutter',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) => Future.value(mockTtiSpan));
        for (final name in ['route', 'ROUTE']) {
          when(
            () => mockEmbrace.startSpan(
              name,
              startTimeMs: any(named: 'startTimeMs'),
            ),
          ).thenAnswer((_) => Future.value(mockTransitionSpan));
        }
        when(() => mockTransitionSpan.addAttribute(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockTransitionSpan.stop(endTimeMs: any(named: 'endTimeMs')))
            .thenAnswer((_) async => true);
        when(() => mockTtiSpan.addAttribute(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockTtiSpan.stop(endTimeMs: any(named: 'endTimeMs')))
            .thenAnswer((_) async => true);
      });

      tearDown(() {
        // ignore: invalid_use_of_visible_for_testing_member
        debugEmbraceOverride = null;
      });

      testWidgets('starts a span named after the route on push',
          (tester) async {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        observer.didPush(route, null);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'route',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => mockTransitionSpan.addAttribute('emb.type', 'view'))
            .called(1);
      });

      testWidgets('ends the span when the transition animation completes',
          (tester) async {
        final animation = FakeAnimation();
        final route = FakeRoute(
          const RouteSettings(name: 'route'),
          animation: animation,
        );
        observer.didPush(route, null);
        await tester.pump();

        verifyNever(
          () => mockTransitionSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        );

        animation.fireStatus(AnimationStatus.completed);

        verify(
          () => mockTransitionSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('ends the span if the transition is interrupted (dismissed)',
          (tester) async {
        final animation = FakeAnimation();
        final route = FakeRoute(
          const RouteSettings(name: 'route'),
          animation: animation,
        );
        observer.didPush(route, null);
        await tester.pump();

        animation.fireStatus(AnimationStatus.dismissed);

        verify(
          () => mockTransitionSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets(
          'ends the span immediately if the animation is already complete',
          (tester) async {
        final animation = FakeAnimation(status: AnimationStatus.completed);
        final route = FakeRoute(
          const RouteSettings(name: 'route'),
          animation: animation,
        );
        observer.didPush(route, null);
        await tester.pump();

        verify(
          () => mockTransitionSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('does not start a transition span when route name is null',
          (tester) async {
        final route = FakeRoute(const RouteSettings());
        observer.didPush(route, null);
        await tester.pump();

        verifyNever(
          () => mockEmbrace.startSpan(
            any(),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        );
      });

      testWidgets('starts a span named after the route on replace',
          (tester) async {
        final animation = FakeAnimation();
        final newRoute = FakeRoute(
          const RouteSettings(name: 'route'),
          animation: animation,
        );
        observer.didReplace(newRoute: newRoute);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'route',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);

        animation.fireStatus(AnimationStatus.completed);
        verify(
          () => mockTransitionSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets(
          'does not start a transition span when newRoute is null on replace',
          (tester) async {
        final oldRoute = FakeRoute(const RouteSettings(name: 'route'));
        observer.didReplace(oldRoute: oldRoute);
        await tester.pump();

        verifyNever(
          () => mockEmbrace.startSpan(
            any(),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        );
      });

      testWidgets('transition span uses name from routeSettingsExtractor',
          (tester) async {
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

      testWidgets('does not start a transition span on pop', (tester) async {
        final route = FakeRoute(const RouteSettings(name: 'route'));
        final previousRoute =
            FakeRoute(const RouteSettings(name: 'previousRoute'));
        observer.didPop(route, previousRoute);
        await tester.pump();

        verifyNever(
          () => mockEmbrace.startSpan(
            any(),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        );
      });
    });
  });
}
