import 'package:embrace/embrace.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'observer_test_helpers.dart';

void main() {
  late EmbraceLifecycleObserver observer;
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
    when(() => mockEmbrace.startSpan('emb-app-background'))
        .thenAnswer((_) => Future.value(mockSpan));
    when(mockSpan.stop).thenAnswer((_) async => true);
    observer = EmbraceLifecycleObserver();
  });

  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    debugEmbraceOverride = null;
  });

  group('EmbraceLifecycleObserver', () {
    test('starts background span on paused', () async {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.value();

      verify(() => mockEmbrace.startSpan('emb-app-background')).called(1);
    });

    test('stops background span on resumed after paused', () async {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.value();
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

      verify(mockSpan.stop).called(1);
    });

    test('stops background span on detached after paused', () async {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.value();
      observer.didChangeAppLifecycleState(AppLifecycleState.detached);

      verify(mockSpan.stop).called(1);
    });

    test('does not stop span when resumed with no prior pause', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      verifyNever(mockSpan.stop);
    });

    test('does not start background span on inactive', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      verifyNever(() => mockEmbrace.startSpan(any()));
    });

    test(
      'stops span immediately if resumed before startSpan resolves',
      () async {
        observer
          ..didChangeAppLifecycleState(AppLifecycleState.paused)
          ..didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future<void>.value();

        verify(mockSpan.stop).called(1);
      },
    );

    test(
      'does not start duplicate background span on repeated paused',
      () async {
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future<void>.value();
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future<void>.value();

        verify(() => mockEmbrace.startSpan('emb-app-background')).called(1);
      },
    );

    test('stops background span when resumed after repeated paused', () async {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.value();
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.value();
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

      verify(mockSpan.stop).called(1);
    });
  });
}
