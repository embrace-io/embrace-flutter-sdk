import 'package:embrace/embrace_samples.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'helpers/helpers.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmbraceSamples', () {
    late EmbracePlatform embracePlatform;

    setUp(() {
      embracePlatform = MockEmbracePlatform();
      EmbracePlatform.instance = embracePlatform;
    });

    group('triggerAnr', () {
      test('calls triggerAnr when platform implementation exists', () {
        when(embracePlatform.triggerAnr).thenAnswer((_) {});
        EmbraceSamples.triggerAnr();
        verify(embracePlatform.triggerAnr).called(1);
      });
    });

    group('triggerNativeSdkError', () {
      test(
          'calls triggerNativeSdkError '
          'when platform implementation exists', () {
        when(embracePlatform.triggerNativeSdkError).thenAnswer((_) {});
        EmbraceSamples.triggerNativeSdkError();
        verify(embracePlatform.triggerNativeSdkError).called(1);
      });
    });

    group('triggerRaisedSignal', () {
      test(
          'calls triggerRaisedSignal '
          'when platform implementation exists', () {
        when(embracePlatform.triggerRaisedSignal).thenAnswer((_) {});
        EmbraceSamples.triggerRaisedSignal();
        verify(embracePlatform.triggerRaisedSignal).called(1);
      });
    });

    group('triggerMethodChannelError', () {
      test(
          'calls triggerMethodChannelError '
          'when platform implementation exists', () {
        when(embracePlatform.triggerMethodChannelError).thenAnswer((_) {});
        EmbraceSamples.triggerMethodChannelError();
        verify(embracePlatform.triggerMethodChannelError).called(1);
      });

      test(
          'logs message when debugging and '
          'platform implementation exists', () {
        when(embracePlatform.triggerMethodChannelError).thenAnswer((_) {});
        final printed = getPrints(EmbraceSamples.triggerMethodChannelError);
        expect(printed, equals(['Starting method channel err!']));
      });
    });

    group('triggerMethodChannelError', () {
      test(
          'calls triggerMethodChannelError '
          'when platform implementation exists', () {
        when(embracePlatform.triggerMethodChannelError).thenAnswer((_) {});
        EmbraceSamples.triggerMethodChannelError();
        verify(embracePlatform.triggerMethodChannelError).called(1);
      });

      test(
          'logs message when debugging and '
          'platform implementation exists', () {
        when(embracePlatform.triggerMethodChannelError).thenAnswer((_) {});
        final printed = getPrints(EmbraceSamples.triggerMethodChannelError);
        expect(printed, equals(['Starting method channel err!']));
      });
    });
    group('triggerCaughtException', () {
      test('does not throw an exception', () {
        expect(EmbraceSamples.triggerCaughtException, returnsNormally);
      });

      test('logs exception message', () {
        final printed = getPrints(EmbraceSamples.triggerCaughtException);
        expect(printed, hasLength(1));
        expect(
          printed.single,
          startsWith(
            'Exception message: Exception: Embrace sample: caught exception, '
            'Stacktrace:\n'
            '#0      EmbraceSamples.triggerCaughtException',
          ),
        );
      });
    });
    group('triggerUncaughtException', () {
      test('throws an exception', () {
        expect(
          EmbraceSamples.triggerUncaughtException,
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('triggerUncaughtError', () {
      test('throws an error', () {
        expect(EmbraceSamples.triggerUncaughtError, throwsA(isA<StateError>()));
      });
    });
    group('triggerUncaughtObject', () {
      test('throws an error with a string instance', () {
        expect(EmbraceSamples.triggerUncaughtObject, throwsA(isA<String>()));
      });
    });
    group('triggerAssert', () {
      test('throws an assertion error', () {
        expect(EmbraceSamples.triggerAssert, throwsAssertionError);
      });
    });
    group('triggerUncaughtExceptionAsync', () {
      test('throws an exception', () async {
        await expectLater(
          EmbraceSamples.triggerUncaughtExceptionAsync,
          throwsException,
        );
      });
    });
  });
}
