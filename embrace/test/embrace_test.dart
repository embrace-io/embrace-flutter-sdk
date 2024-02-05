import 'dart:async';
import 'dart:ui';

import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// PlatformDispatcher.onError is available only for Flutter 3.1 and above.
/// As there is no way to know the Flutter version that runs the test,
/// we enable a flag to disable/enable these tests depending on the version
///
/// To run these test in a version below 3.1 run the following command:
///  `flutter test --dart-define=belowFlutter_3_1=true`
const belowFlutter_3_1 = bool.fromEnvironment('belowFlutter_3_1');

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

class MockEmbrace extends Mock implements Embrace {}

const errorMessage = '__error__';

class MockError {
  @override
  String toString() => errorMessage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Embrace', () {
    late EmbracePlatform embracePlatform;

    setUp(() {
      embracePlatform = MockEmbracePlatform();
      EmbracePlatform.instance = embracePlatform;
    });

    group('instance', () {
      test('can be overridden with debugEmbraceOverride', () {
        final mockEmbrace = MockEmbrace();
        expect(Embrace.instance, isA<Embrace>());
        expect(Embrace.instance, isNot(mockEmbrace));

        debugEmbraceOverride = mockEmbrace;
        expect(Embrace.instance, mockEmbrace);

        debugEmbraceOverride = null;
        expect(Embrace.instance, isA<Embrace>());
        expect(Embrace.instance, isNot(mockEmbrace));
      });
    });

    group('start', () {
      setUp(() {
        when(
          () => embracePlatform.attachToHostSdk(
            enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
          ),
        ).thenAnswer((_) async => true);
      });

      tearDown(() {
        // The global error handling needs to be reset back to the
        // default value before every test
        if (!belowFlutter_3_1) {
          // ignore: avoid_dynamic_calls
          (PlatformDispatcher.instance as dynamic).onError = null;
        }
      });

      test('calls the supplied action', () async {
        var count = 0;
        await Embrace.instance.start(() => count++);
        expect(count, 1);
      });

      group(
        'when in Flutter 3.1 or above',
        () {
          // We can not throw an uncaught error and verify that it called
          // logDartError because any uncaught errors translates to a
          // failed test
          //
          // So we can only directly test if the global error handling method
          // calls logDartError
          test(
            'handles error caught by dispatcher',
            () async {
              await Embrace.instance.start(() async {
                // ignore: avoid_dynamic_calls
                (PlatformDispatcher.instance as dynamic).onError(
                  ArgumentError('Mock argument'),
                  StackTrace.current,
                );
              });
              verify(
                () => embracePlatform.logDartError(
                  any(),
                  'Invalid argument(s): Mock argument',
                  any(),
                  any(),
                  errorType: 'ArgumentError',
                ),
              ).called(1);
            },
          );

          test('does not inject a new error zone', () async {
            final rootErrorZone = Zone.current.errorZone;
            late Zone internalErrorZone;
            await Embrace.instance.start(() async {
              internalErrorZone = Zone.current.errorZone;
            });
            expect(internalErrorZone, rootErrorZone);
          });
        },
        skip: belowFlutter_3_1,
      );

      group(
        'when below Flutter 3.1,',
        () {
          test('Flutter is lower than 3.1', () {
            expect(
              // ignore: avoid_dynamic_calls
              () => (PlatformDispatcher.instance as dynamic).onError,
              throwsNoSuchMethodError,
              reason: 'A version lower than 3.1 is required to run these tests',
            );
          });

          test('catches error', () async {
            await Embrace.instance.start(
              // ignore: only_throw_errors
              () => throw 'Error',
            );
            verify(
              () => embracePlatform.logDartError(
                any(),
                'Error',
                any(),
                any(),
                errorType: 'String',
              ),
            ).called(1);
          });

          test('handles error caught by a zone', () async {
            await Embrace.instance.start(
              () => Zone.current.handleUncaughtError(
                'Error',
                StackTrace.current,
              ),
            );
            verify(
              () => embracePlatform.logDartError(
                any(),
                'Error',
                any(),
                any(),
                errorType: 'String',
              ),
            ).called(1);
          });

          test('injects a new error zone', () async {
            final rootErrorZone = Zone.current.errorZone;
            late Zone internalErrorZone;
            await Embrace.instance.start(() async {
              internalErrorZone = Zone.current.errorZone;
            });
            expect(internalErrorZone, isNot(rootErrorZone));
          });
        },
        skip: !belowFlutter_3_1,
      );

      test('attaches to the host sdk when platform implementation exists', () {
        const enableIntegrationTesting = true;
        Embrace.instance
            .start(() {}, enableIntegrationTesting: enableIntegrationTesting);
        verify(
          () => embracePlatform.attachToHostSdk(
            enableIntegrationTesting: enableIntegrationTesting,
          ),
        ).called(1);
      });
    });

    group('endAppStartup', () {
      const properties = {'key': 'value'};
      test('logs an error when platform implementation exists', () {
        Embrace.instance.endAppStartup(properties: properties);
        verify(() => embracePlatform.endAppStartup(properties)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.endAppStartup(properties))
            .thenThrow(MockError());
        Embrace.instance.endAppStartup(properties: properties);

        verify(
          () => embracePlatform.logInternalError(
            'endAppStartup',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('logBreadcrumb', () {
      const message = '__message__';
      test('adds a breadcrumb when platform implementation exists', () {
        // ignore: deprecated_member_use_from_same_package
        Embrace.instance.logBreadcrumb(message);
        verify(() => embracePlatform.addBreadcrumb(message)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.addBreadcrumb(message))
            .thenThrow(MockError());
        // ignore: deprecated_member_use_from_same_package
        Embrace.instance.logBreadcrumb(message);

        verify(
          () => embracePlatform.logInternalError('addBreadcrumb', errorMessage),
        ).called(1);
      });
    });

    group('addBreadcrumb', () {
      const message = '__message__';
      test('adds a breadcrumb when platform implementation exists', () {
        Embrace.instance.addBreadcrumb(message);
        verify(() => embracePlatform.addBreadcrumb(message)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.addBreadcrumb(message))
            .thenThrow(MockError());
        Embrace.instance.addBreadcrumb(message);

        verify(
          () => embracePlatform.logInternalError('addBreadcrumb', errorMessage),
        ).called(1);
      });
    });

    group('logPushNotification', () {
      const title = '__title__';
      const body = '__body__';
      test('logs a push notification with default parameters', () {
        Embrace.instance.logPushNotification(title, body);
        verify(
          () => embracePlatform.logPushNotification(
            title: title,
            body: body,
            subtitle: null,
            badge: null,
            category: null,
            from: null,
            messageId: null,
            priority: null,
            hasNotification: false,
            hasData: false,
          ),
        ).called(1);
      });

      test('logs a push notification with iOS parameters', () {
        const subtitle = '__subtitle';
        const badge = 0;
        const category = '__category__';

        Embrace.instance.logPushNotification(
          title,
          body,
          subtitle: subtitle,
          badge: badge,
          category: category,
        );
        verify(
          () => embracePlatform.logPushNotification(
            title: title,
            body: body,
            subtitle: subtitle,
            badge: badge,
            category: category,
            from: null,
            messageId: null,
            priority: null,
            hasNotification: false,
            hasData: false,
          ),
        ).called(1);
      });

      test('logs a push notification with Android parameters', () {
        const from = '__from__';
        const messageId = '__id__';
        const priority = 2;
        const hasNotification = true;
        const hasData = true;
        Embrace.instance.logPushNotification(
          title,
          body,
          from: from,
          messageId: messageId,
          priority: priority,
          hasNotification: hasNotification,
          hasData: hasData,
        );
        verify(
          () => embracePlatform.logPushNotification(
            title: title,
            body: body,
            subtitle: null,
            badge: null,
            category: null,
            from: from,
            messageId: messageId,
            priority: 2,
            hasNotification: true,
            hasData: true,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.logPushNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            subtitle: any(named: 'subtitle'),
            badge: any(named: 'badge'),
            category: any(named: 'category'),
            from: any(named: 'from'),
            messageId: any(named: 'messageId'),
            priority: any(named: 'priority'),
            hasNotification: any(named: 'hasNotification'),
            hasData: any(named: 'hasData'),
          ),
        ).thenThrow(MockError());
        Embrace.instance.logPushNotification(title, body);

        verify(
          () => embracePlatform.logInternalError(
            'logPushNotification',
            any(),
          ),
        ).called(1);
      });
    });

    group('logMessage', () {
      const message = '__message__';
      const properties = {'key': 'value'};
      test('log info message', () {
        Embrace.instance.logMessage(
          message,
          Severity.info,
          properties: properties,
        );
        verify(() => embracePlatform.logInfo(message, properties)).called(1);
      });

      test('log warning message', () {
        Embrace.instance
            .logMessage(message, Severity.warning, properties: properties);
        verify(
          () => embracePlatform.logWarning(
            message,
            properties,
            allowScreenshot: false,
          ),
        ).called(1);
      });

      test('log error message', () {
        Embrace.instance.logMessage(
          message,
          Severity.error,
          properties: properties,
        );
        verify(
          () => embracePlatform.logError(
            message,
            properties,
            allowScreenshot: false,
          ),
        ).called(1);
      });
    });

    group('logInfo', () {
      const message = '__message__';
      const properties = {'key': 'value'};
      test('logs an error when platform implementation exists', () {
        Embrace.instance.logInfo(message, properties: properties);
        verify(() => embracePlatform.logInfo(message, properties)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.logInfo(message, properties))
            .thenThrow(MockError());
        Embrace.instance.logInfo(message, properties: properties);

        verify(() => embracePlatform.logInternalError('logInfo', errorMessage))
            .called(1);
      });
    });

    group('logWarning', () {
      const message = '__message__';
      const properties = {'key': 'value'};
      const allowScreenshots = true;
      test('logs a warning when platform implementation exists', () {
        Embrace.instance.logWarning(
          message,
          properties: properties,
          allowScreenshot: allowScreenshots,
        );
        verify(
          () => embracePlatform.logWarning(
            message,
            properties,
            allowScreenshot: allowScreenshots,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.logWarning(
            message,
            properties,
            allowScreenshot: allowScreenshots,
          ),
        ).thenThrow(MockError());
        Embrace.instance.logWarning(
          message,
          properties: properties,
          allowScreenshot: allowScreenshots,
        );

        verify(
          () => embracePlatform.logInternalError(
            'logWarning',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('logError', () {
      const message = '__message__';
      const properties = {'key': 'value'};
      const allowScreenshots = true;
      test('logs an error when platform implementation exists', () {
        Embrace.instance.logError(
          message,
          properties: properties,
          allowScreenshot: allowScreenshots,
        );
        verify(
          () => embracePlatform.logError(
            message,
            properties,
            allowScreenshot: allowScreenshots,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.logError(
            message,
            properties,
            allowScreenshot: allowScreenshots,
          ),
        ).thenThrow(MockError());
        Embrace.instance.logError(
          message,
          properties: properties,
          allowScreenshot: allowScreenshots,
        );

        verify(
          () => embracePlatform.logInternalError(
            'logError',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('logNetworkRequest', () {
      const url = '__url__';
      const method = HttpMethod.get;
      const startTime = 123;
      const endTime = 321;
      const bytesSent = 222;
      const bytesReceived = 333;
      const statusCode = 200;
      const error = '__error__';
      const traceId = '__traceId__';
      test(
          'logs the specified network request when '
          'platform implementation exists', () {
        // ignore: deprecated_member_use_from_same_package
        Embrace.instance.logNetworkRequest(
          url: url,
          method: method,
          startTime: startTime,
          endTime: endTime,
          bytesSent: bytesSent,
          bytesReceived: bytesReceived,
          statusCode: statusCode,
          error: error,
          traceId: traceId,
        );
        verify(
          () => embracePlatform.logNetworkRequest(
            url: url,
            method: method,
            startTime: startTime,
            endTime: endTime,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            statusCode: statusCode,
            error: error,
            traceId: traceId,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.logNetworkRequest(
            url: url,
            method: method,
            startTime: startTime,
            endTime: endTime,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            statusCode: statusCode,
            error: error,
            traceId: traceId,
          ),
        ).thenThrow(MockError());
        // ignore: deprecated_member_use_from_same_package
        Embrace.instance.logNetworkRequest(
          url: url,
          method: method,
          startTime: startTime,
          endTime: endTime,
          bytesSent: bytesSent,
          bytesReceived: bytesReceived,
          statusCode: statusCode,
          error: error,
          traceId: traceId,
        );

        verify(
          () => embracePlatform.logInternalError(
            'logNetworkRequest',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('recordNetworkRequest', () {
      const url = '__url__';
      const method = HttpMethod.get;
      const startTime = 123;
      const endTime = 321;
      const bytesSent = 222;
      const bytesReceived = 333;
      const statusCode = 200;
      const error = '__error__';
      const traceId = '__traceId__';
      test('record completed request', () {
        final request = EmbraceNetworkRequest.fromCompletedRequest(
          url: url,
          httpMethod: method,
          startTime: startTime,
          endTime: endTime,
          bytesSent: bytesSent,
          bytesReceived: bytesReceived,
          statusCode: statusCode,
        );
        Embrace.instance.recordNetworkRequest(request);
        verify(
          () => embracePlatform.logNetworkRequest(
            url: url,
            method: method,
            startTime: startTime,
            endTime: endTime,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            statusCode: statusCode,
          ),
        ).called(1);
      });

      test('record incomplete request', () {
        final request = EmbraceNetworkRequest.fromIncompleteRequest(
          url: url,
          httpMethod: method,
          startTime: startTime,
          endTime: endTime,
          errorDetails: error,
          traceId: traceId,
        );
        Embrace.instance.recordNetworkRequest(request);
        verify(
          () => embracePlatform.logNetworkRequest(
            url: url,
            method: method,
            startTime: startTime,
            endTime: endTime,
            bytesSent: -1,
            bytesReceived: -1,
            statusCode: -1,
            error: error,
            traceId: traceId,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.logNetworkRequest(
            url: url,
            method: method,
            startTime: startTime,
            endTime: endTime,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            statusCode: statusCode,
          ),
        ).thenThrow(MockError());

        final request = EmbraceNetworkRequest.fromCompletedRequest(
          url: url,
          httpMethod: method,
          startTime: startTime,
          endTime: endTime,
          bytesSent: bytesSent,
          bytesReceived: bytesReceived,
          statusCode: statusCode,
        );
        Embrace.instance.recordNetworkRequest(request);

        verify(
          () => embracePlatform.logInternalError(
            'logNetworkRequest',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('logDartError', () {
      var stackStr = '';
      test(
          'starts the specified moment when '
          'platform implementation exists', () {
        try {
          throw Exception('Test exception');
        } catch (error, stack) {
          stackStr = stack.toString();
          Embrace.instance.logDartError(
            error,
            stack,
          );
        }
        verify(
          () => embracePlatform.logDartError(
            stackStr,
            'Exception: Test exception',
            null,
            null,
            errorType: '_Exception',
            // ignore: avoid_redundant_argument_values
            wasHandled: false,
          ),
        ).called(1);
      });
    });

    group('logHandledDartError', () {
      var stackStr = '';
      test(
          'starts the specified moment when '
          'platform implementation exists', () {
        try {
          throw Exception('Test exception');
        } catch (error, stack) {
          stackStr = stack.toString();
          Embrace.instance.logHandledDartError(
            error,
            stack,
          );
        }
        verify(
          () => embracePlatform.logDartError(
            stackStr,
            'Exception: Test exception',
            null,
            null,
            errorType: '_Exception',
            wasHandled: true,
          ),
        ).called(1);
      });
    });

    group('startMoment', () {
      const momentName = '__momentName__';
      const identifier = '__identifier__';
      const properties = {'key': 'value'};
      const allowScreenshots = true;
      test(
          'starts the specified moment when '
          'platform implementation exists', () {
        Embrace.instance.startMoment(
          momentName,
          identifier: identifier,
          properties: properties,
          allowScreenshot: allowScreenshots,
        );
        verify(
          () => embracePlatform.startMoment(
            momentName,
            identifier,
            properties,
            allowScreenshot: allowScreenshots,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.startMoment(
            momentName,
            identifier,
            properties,
            allowScreenshot: allowScreenshots,
          ),
        ).thenThrow(MockError());
        Embrace.instance.startMoment(
          momentName,
          identifier: identifier,
          properties: properties,
          allowScreenshot: allowScreenshots,
        );

        verify(
          () => embracePlatform.logInternalError(
            'startMoment',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('endMoment', () {
      const momentName = '__momentName__';
      const identifier = '__identifier__';
      const properties = {'key': 'value'};
      test('ends the specified moment when platform implementation exists', () {
        Embrace.instance.endMoment(
          momentName,
          identifier: identifier,
          properties: properties,
        );
        verify(
          () => embracePlatform.endMoment(
            momentName,
            identifier,
            properties,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.endMoment(
            momentName,
            identifier,
            properties,
          ),
        ).thenThrow(MockError());
        Embrace.instance.endMoment(
          momentName,
          identifier: identifier,
          properties: properties,
        );

        verify(
          () => embracePlatform.logInternalError(
            'endMoment',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('startView', () {
      const view = '__view__';
      test('starts the specified view when platform implementation exists', () {
        Embrace.instance.startView(view);
        verify(() => embracePlatform.startView(view)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.startView(view)).thenThrow(MockError());
        Embrace.instance.startView(view);

        verify(
          () => embracePlatform.logInternalError(
            'startView',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('endView', () {
      const view = '__view__';
      test('ends the specified view when platform implementation exists', () {
        Embrace.instance.endView(view);
        verify(() => embracePlatform.endView(view)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.endView(view)).thenThrow(MockError());
        Embrace.instance.endView(view);

        verify(
          () => embracePlatform.logInternalError(
            'endView',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('setUserIdentifier', () {
      const userIdentifier = '__userIdentifier__';
      test('sets the user name when platform implementation exists', () {
        Embrace.instance.setUserIdentifier(userIdentifier);
        verify(() => embracePlatform.setUserIdentifier(userIdentifier))
            .called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.setUserIdentifier(userIdentifier))
            .thenThrow(MockError());
        Embrace.instance.setUserIdentifier(userIdentifier);

        verify(
          () => embracePlatform.logInternalError(
            'setUserIdentifier',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('clearUserIdentifier', () {
      test(
          'clears the user identifier when '
          'platform implementation exists', () {
        Embrace.instance.clearUserIdentifier();
        verify(embracePlatform.clearUserIdentifier).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(embracePlatform.clearUserIdentifier).thenThrow(MockError());
        Embrace.instance.clearUserIdentifier();

        verify(
          () => embracePlatform.logInternalError(
            'clearUserIdentifier',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('setUserName', () {
      const userName = '__userName__';
      test('sets the user name when platform implementation exists', () {
        Embrace.instance.setUserName(userName);
        verify(() => embracePlatform.setUserName(userName)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.setUserName(userName))
            .thenThrow(MockError());
        Embrace.instance.setUserName(userName);

        verify(
          () => embracePlatform.logInternalError(
            'setUserName',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('clearUserName', () {
      test('sets the user email when platform implementation exists', () {
        Embrace.instance.clearUserName();
        verify(embracePlatform.clearUserName).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(embracePlatform.clearUserName).thenThrow(MockError());
        Embrace.instance.clearUserName();

        verify(
          () => embracePlatform.logInternalError(
            'clearUserName',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('setUserEmail', () {
      const email = '__email__';
      test('sets the user email when platform implementation exists', () {
        Embrace.instance.setUserEmail(email);
        verify(() => embracePlatform.setUserEmail(email)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.setUserEmail(email)).thenThrow(MockError());
        Embrace.instance.setUserEmail(email);

        verify(
          () => embracePlatform.logInternalError(
            'setUserEmail',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('clearUserEmail', () {
      test('clears the user email when platform implementation exists', () {
        Embrace.instance.clearUserEmail();
        verify(embracePlatform.clearUserEmail).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(embracePlatform.clearUserEmail).thenThrow(MockError());
        Embrace.instance.clearUserEmail();

        verify(
          () => embracePlatform.logInternalError(
            'clearUserEmail',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('setUserAsPayer', () {
      test('sets the user as payer when platform implementation exists', () {
        Embrace.instance.setUserAsPayer();
        verify(embracePlatform.setUserAsPayer).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(embracePlatform.setUserAsPayer).thenThrow(MockError());
        Embrace.instance.setUserAsPayer();

        verify(
          () => embracePlatform.logInternalError(
            'setUserAsPayer',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('clearUserAsPayer', () {
      test('clears the user as payer when platform implementation exists', () {
        Embrace.instance.clearUserAsPayer();
        verify(embracePlatform.clearUserAsPayer).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(embracePlatform.clearUserAsPayer).thenThrow(MockError());
        Embrace.instance.clearUserAsPayer();

        verify(
          () => embracePlatform.logInternalError(
            'clearUserAsPayer',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('addUserPersona', () {
      const persona = '__persona__';
      test('sets the user persona when platform implementation exists', () {
        Embrace.instance.addUserPersona(persona);
        verify(() => embracePlatform.addUserPersona(persona)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.addUserPersona(persona))
            .thenThrow(MockError());
        Embrace.instance.addUserPersona(persona);

        verify(
          () => embracePlatform.logInternalError(
            'addUserPersona',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('setUserPersona', () {
      const persona = '__persona__';
      test('sets the user persona when platform implementation exists', () {
        // ignore: deprecated_member_use_from_same_package
        Embrace.instance.setUserPersona(persona);
        verify(() => embracePlatform.addUserPersona(persona)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.addUserPersona(persona))
            .thenThrow(MockError());
        // ignore: deprecated_member_use_from_same_package
        Embrace.instance.setUserPersona(persona);

        verify(
          () => embracePlatform.logInternalError(
            'addUserPersona',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('clearUserPersona', () {
      const persona = '__persona__';
      test('clears the user persona when platform implementation exists', () {
        Embrace.instance.clearUserPersona(persona);
        verify(() => embracePlatform.clearUserPersona(persona)).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.clearUserPersona(persona))
            .thenThrow(MockError());
        Embrace.instance.clearUserPersona(persona);

        verify(
          () => embracePlatform.logInternalError(
            'clearUserPersona',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('clearAllUserPersonas', () {
      test('clears user personas when platform implementation exists', () {
        Embrace.instance.clearAllUserPersonas();
        verify(embracePlatform.clearAllUserPersonas).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(embracePlatform.clearAllUserPersonas).thenThrow(MockError());
        Embrace.instance.clearAllUserPersonas();

        verify(
          () => embracePlatform.logInternalError(
            'clearAllUserPersonas',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('addSessionProperty', () {
      const key = '__key__';
      const value = '__value__';
      const permanent = false;
      test('adds session property when platform implementation exists', () {
        Embrace.instance.addSessionProperty(key, value);
        verify(
          () => embracePlatform.addSessionProperty(
            key,
            value,
            permanent: permanent,
          ),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(
          () => embracePlatform.addSessionProperty(
            key,
            value,
            permanent: permanent,
          ),
        ).thenThrow(MockError());
        Embrace.instance.addSessionProperty(key, value);

        verify(
          () => embracePlatform.logInternalError(
            'addSessionProperty',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('removeSessionProperty', () {
      const key = '__key__';
      test('removes session property when platform implementation exists', () {
        Embrace.instance.removeSessionProperty(key);
        verify(
          () => embracePlatform.removeSessionProperty(key),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.removeSessionProperty(key))
            .thenThrow(MockError());
        Embrace.instance.removeSessionProperty(key);

        verify(
          () => embracePlatform.logInternalError(
            'removeSessionProperty',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('getSessionProperties', () {
      test('getSessionProperties when platform implementation exists', () {
        Embrace.instance.getSessionProperties();
        verify(
          () => embracePlatform.getSessionProperties(),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.getSessionProperties())
            .thenThrow(MockError());
        final properties = Embrace.instance.getSessionProperties();

        expect(properties, isA<Future<Map<String, String>>>());

        verify(
          () => embracePlatform.logInternalError(
            'getSessionProperties',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('endSession', () {
      test('ends session when platform implementation exists', () {
        Embrace.instance.endSession();
        verify(
          () => embracePlatform.endSession(
            clearUserInfo: any(named: 'clearUserInfo'),
          ),
        ).called(1);
      });

      test('clearUserInfo defaults to true', () {
        Embrace.instance.endSession();
        verify(
          // ignore: avoid_redundant_argument_values
          () => embracePlatform.endSession(clearUserInfo: true),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.endSession()).thenThrow(MockError());
        Embrace.instance.endSession();

        verify(
          () => embracePlatform.logInternalError(
            'endSession',
            errorMessage,
          ),
        ).called(1);
      });
    });

    group('getDeviceId', () {
      test('returns device ID when platform implementation exists', () async {
        const platformName = '__test_platform__';
        when(embracePlatform.getDeviceId).thenAnswer((_) async => platformName);

        final actualPlatformName = await Embrace.instance.getDeviceId();
        expect(actualPlatformName, equals(platformName));
      });
    });

    group('getLastRunEndState', () {
      test('getLastRunEndState when platform implementation exists', () {
        Embrace.instance.getLastRunEndState();
        verify(
          () => embracePlatform.getLastRunEndState(),
        ).called(1);
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.getLastRunEndState()).thenThrow(MockError());
        final state = Embrace.instance.getLastRunEndState();

        expect(state, isA<Future<LastRunEndState>>());

        verify(
          () => embracePlatform.logInternalError(
            'getLastRunEndState',
            errorMessage,
          ),
        ).called(1);
      });
    });
    group('getCurrentSessionId', () {
      test('returns current session ID when platform implementation exists',
          () {
        final id = Embrace.instance.getCurrentSessionId();
        verify(
          () => embracePlatform.getCurrentSessionId(),
        ).called(1);

        expect(id, isA<Future<String?>>());
      });

      test(
          'logs internal error when platform implementation '
          'throws an error', () {
        when(() => embracePlatform.getCurrentSessionId())
            .thenThrow(MockError());

        Embrace.instance.getCurrentSessionId();

        verify(
          () => embracePlatform.logInternalError(
            'getCurrentSessionId',
            errorMessage,
          ),
        ).called(1);
      });
    });
  });
}
