import 'package:embrace/embrace.dart';
import 'package:embrace_go_router/embrace_go_router.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'observer_test_helpers.dart';

GoRouter _buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
    ],
  );
}

void main() {
  late EmbraceGoRouterObserver observer;

  setUp(() {
    observer = EmbraceGoRouterObserver();
  });

  // The TTI span's one-shot guard is static/global — reset it after every
  // test in this file, not just the ones that exercise it directly, since
  // any didPush/didReplace/route change (e.g. in the 'view tracking' and
  // 'state span' groups) trips it too.
  tearDown(
    // ignore: invalid_use_of_visible_for_testing_member
    EmbraceGoRouterObserver.resetTtiSpanForTesting,
  );

  group('NavigatorObserver mode (no router)', () {
    group('view tracking', () {
      late MockEmbracePlatform platform;

      setUp(() {
        platform = MockEmbracePlatform();
        EmbracePlatform.instance = platform;
      });

      group('didPush', () {
        test('starts new view', () {
          final route = FakeRoute(const RouteSettings(name: '/route'));
          observer.didPush(route, null);
          verify(() => platform.startView('/route')).called(1);
        });

        test('ends previous view', () {
          final route = FakeRoute(const RouteSettings(name: '/route'));
          final previousRoute =
              FakeRoute(const RouteSettings(name: '/previous'));
          observer.didPush(route, previousRoute);
          verify(() => platform.endView('/previous')).called(1);
        });

        test('does not end view if previousRoute is null', () {
          final route = FakeRoute(const RouteSettings(name: '/route'));
          observer.didPush(route, null);
          verifyNever(() => platform.endView(any()));
        });

        test('can use custom name via routeSettingsExtractor', () {
          final observer = EmbraceGoRouterObserver(
            routeSettingsExtractor: (route) =>
                RouteSettings(name: route.settings.name?.toUpperCase()),
          );
          final route = FakeRoute(const RouteSettings(name: '/route'));
          observer.didPush(route, null);
          verify(() => platform.startView('/ROUTE')).called(1);
        });
      });

      group('didReplace', () {
        test('starts new view', () {
          final newRoute = FakeRoute(const RouteSettings(name: '/new'));
          final oldRoute = FakeRoute(const RouteSettings(name: '/old'));
          observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);
          verify(() => platform.startView('/new')).called(1);
        });

        test('ends old view', () {
          final newRoute = FakeRoute(const RouteSettings(name: '/new'));
          final oldRoute = FakeRoute(const RouteSettings(name: '/old'));
          observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);
          verify(() => platform.endView('/old')).called(1);
        });
      });

      group('didPop', () {
        test('starts previous view', () {
          final route = FakeRoute(const RouteSettings(name: '/route'));
          final previousRoute =
              FakeRoute(const RouteSettings(name: '/previous'));
          observer.didPop(route, previousRoute);
          verify(() => platform.startView('/previous')).called(1);
        });

        test('ends popped view', () {
          final route = FakeRoute(const RouteSettings(name: '/route'));
          final previousRoute =
              FakeRoute(const RouteSettings(name: '/previous'));
          observer.didPop(route, previousRoute);
          verify(() => platform.endView('/route')).called(1);
        });

        test('does not start view if previousRoute is null', () {
          final route = FakeRoute(const RouteSettings(name: '/route'));
          observer.didPop(route, null);
          verifyNever(() => platform.startView(any()));
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
        final route = FakeRoute(const RouteSettings(name: '/route'));
        observer.didPush(route, null);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'emb-time-to-interactive-flutter',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => mockSpan.addAttribute('route', '/route')).called(1);
        verify(
          () => mockSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('only starts the TTI span once, on the first navigation',
          (tester) async {
        final firstRoute = FakeRoute(const RouteSettings(name: '/first'));
        final secondRoute = FakeRoute(const RouteSettings(name: '/second'));
        observer.didPush(firstRoute, null);
        await tester.pump();
        observer.didPush(secondRoute, firstRoute);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'emb-time-to-interactive-flutter',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => mockSpan.addAttribute('route', '/first')).called(1);
        verifyNever(() => mockSpan.addAttribute('route', '/second'));
      });

      testWidgets('TTI span uses name from routeSettingsExtractor',
          (tester) async {
        final observer = EmbraceGoRouterObserver(
          routeSettingsExtractor: (route) =>
              RouteSettings(name: route.settings.name?.toUpperCase()),
        );
        final route = FakeRoute(const RouteSettings(name: '/route'));
        observer.didPush(route, null);
        await tester.pump();

        verify(() => mockSpan.addAttribute('route', '/ROUTE')).called(1);
      });

      testWidgets('does not start a TTI span when route name is null',
          (tester) async {
        final route = FakeRoute(const RouteSettings());
        observer.didPush(route, null);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });

      testWidgets('starts a TTI span on replace', (tester) async {
        final newRoute = FakeRoute(const RouteSettings(name: '/new'));
        observer.didReplace(newRoute: newRoute);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'emb-time-to-interactive-flutter',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => mockSpan.addAttribute('route', '/new')).called(1);
        verify(
          () => mockSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets('does not start a TTI span when newRoute is null on replace',
          (tester) async {
        final oldRoute = FakeRoute(const RouteSettings(name: '/old'));
        observer.didReplace(oldRoute: oldRoute);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });

      testWidgets('does not start a TTI span on pop', (tester) async {
        final route = FakeRoute(const RouteSettings(name: '/route'));
        final previousRoute = FakeRoute(const RouteSettings(name: '/previous'));
        observer.didPop(route, previousRoute);
        await tester.pump();

        verifyNever(() => mockEmbrace.startSpan(any()));
      });
    });
  });

  group('delegate mode (router provided)', () {
    late MockEmbrace mockEmbrace;
    late MockEmbraceSpan mockStateSpan;
    late MockEmbraceSpan mockTtiSpan;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(<String, String>{});
    });

    setUp(() {
      mockEmbrace = MockEmbrace();
      mockStateSpan = MockEmbraceSpan();
      mockTtiSpan = MockEmbraceSpan();
      // ignore: invalid_use_of_visible_for_testing_member
      debugEmbraceOverride = mockEmbrace;
      when(
        () => mockEmbrace.startSpan('emb-state-screen-flutter-automatic'),
      ).thenAnswer((_) => Future.value(mockStateSpan));
      when(
        () => mockEmbrace.startSpan(
          'emb-time-to-interactive-flutter',
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) => Future.value(mockTtiSpan));
      when(() => mockStateSpan.addAttribute(any(), any()))
          .thenAnswer((_) async => true);
      when(
        () => mockStateSpan.addEvent(
          any(),
          attributes: any(named: 'attributes'),
        ),
      ).thenAnswer((_) async => true);
      when(() => mockStateSpan.stop()).thenAnswer((_) async => true);
      when(() => mockTtiSpan.addAttribute(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockTtiSpan.stop(endTimeMs: any(named: 'endTimeMs')))
          .thenAnswer((_) async => true);
    });

    tearDown(() {
      // ignore: invalid_use_of_visible_for_testing_member
      debugEmbraceOverride = null;
    });

    group('state span', () {
      testWidgets('creates state span on initialization', (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        EmbraceGoRouterObserver(router: router);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan('emb-state-screen-flutter-automatic'),
        ).called(1);
      });

      testWidgets('sets emb.type and initial_value attributes on span',
          (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        EmbraceGoRouterObserver(router: router);
        await tester.pump();

        verify(() => mockStateSpan.addAttribute('emb.type', 'state')).called(1);
        verify(
          () => mockStateSpan.addAttribute('emb.state.initial_value', '/'),
        ).called(1);
      });

      testWidgets('adds transition event on route change', (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final obs = EmbraceGoRouterObserver(router: router);
        addTearDown(obs.dispose);
        await tester.pump();

        router.go('/home');
        await tester.pump();

        verify(
          () => mockStateSpan.addEvent(
            'transition',
            attributes: {'emb.state.new_value': '/home'},
          ),
        ).called(1);
      });

      testWidgets('does not add duplicate transition for same route',
          (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final obs = EmbraceGoRouterObserver(router: router);
        addTearDown(obs.dispose);
        await tester.pump();

        router.go('/home');
        await tester.pump();
        router.go('/home');
        await tester.pump();

        verify(
          () => mockStateSpan.addEvent(
            'transition',
            attributes: {'emb.state.new_value': '/home'},
          ),
        ).called(1);
      });

      testWidgets('stops span with transition count on dispose',
          (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final obs = EmbraceGoRouterObserver(router: router);
        await tester.pump();

        router.go('/home');
        await tester.pump();

        obs.dispose();
        await tester.pump();

        verify(
          () => mockStateSpan.addAttribute('emb.state.transition_count', '1'),
        ).called(1);
        verify(() => mockStateSpan.stop()).called(1);
      });

      testWidgets('does not add transitions after dispose', (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        EmbraceGoRouterObserver(router: router).dispose();
        await tester.pump();

        router.go('/home');
        await tester.pump();

        verifyNever(
          () => mockStateSpan.addEvent(
            'transition',
            attributes: {'emb.state.new_value': '/home'},
          ),
        );
      });

      testWidgets('stops span when dispose races startSpan Future',
          (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        // Dispose before the startSpan Future resolves.
        EmbraceGoRouterObserver(router: router).dispose();
        await tester.pump();

        verify(() => mockStateSpan.stop()).called(1);
      });

      testWidgets('NavigatorObserver callbacks are no-ops in delegate mode',
          (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final obs = EmbraceGoRouterObserver(router: router);
        addTearDown(obs.dispose);
        await tester.pump();

        obs
          ..didPush(FakeRoute(const RouteSettings(name: '/other')), null)
          ..didPop(FakeRoute(const RouteSettings(name: '/other')), null)
          ..didReplace(
            newRoute: FakeRoute(const RouteSettings(name: '/other')),
          );

        verifyNever(
          () => mockStateSpan.addEvent(
            'transition',
            attributes: {'emb.state.new_value': '/other'},
          ),
        );
      });
    });

    group('TTI spans', () {
      testWidgets('starts a TTI span for the initial route', (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        EmbraceGoRouterObserver(router: router);
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'emb-time-to-interactive-flutter',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verify(() => mockTtiSpan.addAttribute('route', '/')).called(1);
        verify(
          () => mockTtiSpan.stop(endTimeMs: any(named: 'endTimeMs')),
        ).called(1);
      });

      testWidgets(
          'does not start another TTI span on subsequent route '
          'changes', (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final obs = EmbraceGoRouterObserver(router: router);
        addTearDown(obs.dispose);
        await tester.pump();

        router.go('/home');
        await tester.pump();

        verify(
          () => mockEmbrace.startSpan(
            'emb-time-to-interactive-flutter',
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).called(1);
        verifyNever(() => mockTtiSpan.addAttribute('route', '/home'));
      });
    });
  });
}
