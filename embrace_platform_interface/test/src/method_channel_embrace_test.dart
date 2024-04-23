import 'package:embrace_platform_interface/http_method.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:embrace_platform_interface/method_channel_embrace.dart';
import 'package:embrace_platform_interface/src/version.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kDeviceId = 'mock';
  const dartVersion = '2.0.0';

  group('$MethodChannelEmbrace', () {
    late MethodChannelEmbrace methodChannelEmbrace;
    final log = <MethodCall>[];

    setUp(() async {
      methodChannelEmbrace = MethodChannelEmbrace(
        platform: FakePlatform(
          version: dartVersion,
          operatingSystem: Platform.android,
        ),
      )..methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'getDeviceId':
              return kDeviceId;
            case 'attachToHostSdk':
              return true;
            case 'getSdkVersion':
              return '6.3.0';
            default:
              return null;
          }
        });
    });

    tearDown(log.clear);

    group('attachToHostSdk', () {
      test('returns true if platform initializes correctly', () async {
        expect(
          await methodChannelEmbrace.attachToHostSdk(
            enableIntegrationTesting: false,
          ),
          true,
        );
      });

      test('returns false if already initialized', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );

        expect(
          await methodChannelEmbrace.attachToHostSdk(
            enableIntegrationTesting: false,
          ),
          false,
        );
      });

      test('returns false if platform returns null', () async {
        methodChannelEmbrace.methodChannel
            .setMockMethodCallHandler((MethodCall methodCall) async {
          return null;
        });

        expect(
          await methodChannelEmbrace.attachToHostSdk(
            enableIntegrationTesting: false,
          ),
          false,
        );
      });

      test('invokes attachToHostSdk method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );

        expect(
          log,
          contains(
            isMethodCall(
              'attachToHostSdk',
              arguments: {
                'enableIntegrationTesting': false,
                'embraceFlutterSdkVersion': packageVersion,
                'dartRuntimeVersion': dartVersion,
              },
            ),
          ),
        );
      });
    });

    group('endAppStartup', () {
      const properties = {'key': 'value'};
      test('invokes endStartupMoment method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.endAppStartup(properties);
        expect(
          log,
          contains(
            isMethodCall(
              'endStartupMoment',
              arguments: {'properties': properties},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.endAppStartup(properties),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('logBreadcrumb', () {
      const message = '__message__';
      test('invokes logBreadcrumb method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logBreadcrumb(message);
        expect(
          log,
          contains(
            isMethodCall(
              'addBreadcrumb',
              arguments: {'message': message},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.logBreadcrumb(message),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('addBreadcrumb', () {
      const message = '__message__';
      test('invokes addBreadcrumb method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.addBreadcrumb(message);
        expect(
          log,
          contains(
            isMethodCall(
              'addBreadcrumb',
              arguments: {'message': message},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.addBreadcrumb(message),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('logInfo', () {
      const properties = {'key': 'value'};
      const message = '__message__';
      test('invokes logInfo method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logInfo(message, properties);
        expect(
          log,
          contains(
            isMethodCall(
              'logInfo',
              arguments: {'message': message, 'properties': properties},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.logInfo(message, properties),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('logWarning', () {
      const properties = {'key': 'value'};
      const message = '__message__';
      test('invokes logWarning method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logWarning(
          message,
          properties,
        );
        expect(
          log,
          contains(
            isMethodCall(
              'logWarning',
              arguments: {
                'message': message,
                'properties': properties,
              },
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.logWarning(
            message,
            properties,
          ),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    test('getDeviceId', () async {
      final deviceId = await methodChannelEmbrace.getDeviceId();
      expect(
        log,
        <Matcher>[isMethodCall('getDeviceId', arguments: null)],
      );
      expect(deviceId, equals(kDeviceId));
    });
    group('logError', () {
      const properties = {'key': 'value'};
      const message = '__message__';
      test('invokes logError method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logError(
          message,
          properties,
        );
        expect(
          log,
          contains(
            isMethodCall(
              'logError',
              arguments: {
                'message': message,
                'properties': properties,
              },
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.logError(
            message,
            properties,
          ),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('logNetworkRequest', () {
      const url = '__url__';
      const httpMethod = HttpMethod.get;
      const startTime = 1234;
      const endTime = 4321;
      const bytesSent = 222;
      const bytesReceived = 444;
      const statusCode = 200;
      const error = '__error__';
      const traceId = '__trace__';
      test('invokes logNetworkRequest method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logNetworkRequest(
          url: url,
          method: httpMethod,
          startTime: startTime,
          endTime: endTime,
          bytesSent: bytesSent,
          bytesReceived: bytesReceived,
          statusCode: statusCode,
          error: error,
          traceId: traceId,
        );
        expect(
          log,
          contains(
            isMethodCall(
              'logNetworkRequest',
              arguments: {
                'url': url,
                'httpMethod': 'get',
                'startTime': startTime,
                'endTime': endTime,
                'bytesSent': bytesSent,
                'bytesReceived': bytesReceived,
                'statusCode': statusCode,
                'error': error,
                'traceId': traceId,
              },
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.logNetworkRequest(
            url: url,
            method: httpMethod,
            startTime: startTime,
            endTime: endTime,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            statusCode: statusCode,
            error: error,
            traceId: traceId,
          ),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('startView', () {
      const viewName = '__view__';
      test('invokes startView method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.startView(viewName);
        expect(
          log,
          contains(
            isMethodCall('startView', arguments: {'name': viewName}),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.startView(viewName),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('endView', () {
      const viewName = '__view__';
      test('invokes endView method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.endView(viewName);
        expect(
          log,
          contains(
            isMethodCall('endView', arguments: {'name': viewName}),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.endView(viewName),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('startMoment', () {
      const name = '__name__';
      const identifier = '__identifier__';
      const properties = {'key': 'value'};
      test('invokes startMoment method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.startMoment(
          name,
          identifier,
          properties,
        );
        expect(
          log,
          contains(
            isMethodCall(
              'startMoment',
              arguments: {
                'name': name,
                'identifier': identifier,
                'properties': properties,
              },
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.startMoment(
            name,
            identifier,
            properties,
          ),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('endMoment', () {
      const name = '__name__';
      const identifier = '__identifier__';
      const properties = {'key': 'value'};
      test('invokes endMoment method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.endMoment(
          name,
          identifier,
          properties,
        );
        expect(
          log,
          contains(
            isMethodCall(
              'endMoment',
              arguments: {
                'name': name,
                'identifier': identifier,
                'properties': properties,
              },
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.endMoment(
            name,
            identifier,
            properties,
          ),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    test('getDeviceId', () async {
      final deviceId = await methodChannelEmbrace.getDeviceId();
      expect(
        log,
        <Matcher>[isMethodCall('getDeviceId', arguments: null)],
      );
      expect(deviceId, equals(kDeviceId));
    });

    group('triggerNativeSdkError', () {
      test('invokes triggerNativeSdkError method in the method channel',
          () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.triggerNativeSdkError();
        expect(
          log,
          contains(
            isMethodCall(
              'triggerNativeSdkError',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.triggerNativeSdkError,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('triggerAnr', () {
      test('invokes triggerAnr method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.triggerAnr();
        expect(
          log,
          contains(
            isMethodCall(
              'triggerAnr',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.triggerAnr,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('triggerRaisedSignal', () {
      test(
          'invokes triggerRaisedSignal method in '
          'the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.triggerRaisedSignal();
        expect(
          log,
          contains(
            isMethodCall(
              'triggerRaisedSignal',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.triggerRaisedSignal,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('triggerMethodChannelError', () {
      test(
          'invokes triggerMethodChannelError method in '
          'the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.triggerMethodChannelError();
        expect(
          log,
          contains(
            isMethodCall(
              'triggerMethodChannelError',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.triggerMethodChannelError,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('setUserIdentifier', () {
      const userIdentifier = '__userIdentifier__';
      test('invokes setUserIdentifier method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.setUserIdentifier(userIdentifier);
        expect(
          log,
          contains(
            isMethodCall(
              'setUserIdentifier',
              arguments: {'identifier': userIdentifier},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.setUserIdentifier(userIdentifier),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('clearUserIdentifier', () {
      test(
          'invokes clearUserIdentifier method in '
          'the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.clearUserIdentifier();
        expect(
          log,
          contains(
            isMethodCall(
              'clearUserIdentifier',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.clearUserIdentifier,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('setUserName', () {
      const userName = '__userName__';
      test('invokes setUserName method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.setUserName(userName);
        expect(
          log,
          contains(
            isMethodCall(
              'setUserName',
              arguments: {'name': userName},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.setUserName(userName),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('clearUserName', () {
      test('invokes clearUserName method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.clearUserName();
        expect(
          log,
          contains(
            isMethodCall(
              'clearUserName',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.clearUserName,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('setUserEmail', () {
      const userEmail = '__userEmail__';
      test('invokes setUserEmail method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.setUserEmail(userEmail);
        expect(
          log,
          contains(
            isMethodCall(
              'setUserEmail',
              arguments: {'email': userEmail},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.setUserEmail(userEmail),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('clearUserEmail', () {
      test('invokes clearUserEmail method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.clearUserEmail();
        expect(
          log,
          contains(
            isMethodCall(
              'clearUserEmail',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.clearUserEmail,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('setUserAsPayer', () {
      test('invokes setUserAsPayer method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.setUserAsPayer();
        expect(
          log,
          contains(
            isMethodCall(
              'setUserAsPayer',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.setUserAsPayer,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('clearUserAsPayer', () {
      test('invokes clearUserAsPayer method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.clearUserAsPayer();
        expect(
          log,
          contains(
            isMethodCall(
              'clearUserAsPayer',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.clearUserAsPayer,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('addUserPersona', () {
      const persona = '__persona__';
      test('invokes addUserPersona method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.addUserPersona(persona);
        expect(
          log,
          contains(
            isMethodCall(
              'addUserPersona',
              arguments: {'persona': persona},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.addUserPersona(persona),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('clearUserPersona', () {
      const persona = '__persona__';
      test('invokes clearUserPersona method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.clearUserPersona(persona);
        expect(
          log,
          contains(
            isMethodCall(
              'clearUserPersona',
              arguments: {'persona': persona},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.clearUserPersona(persona),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('clearAllUserPersonas', () {
      test(
          'invokes clearAllUserPersonas method in the '
          'method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.clearAllUserPersonas();
        expect(
          log,
          contains(
            isMethodCall(
              'clearAllUserPersonas',
              arguments: null,
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          methodChannelEmbrace.clearAllUserPersonas,
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('addSessionProperty', () {
      const key = '__key__';
      const value = '__value__';
      test('invokes addSessionProperty method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.addSessionProperty(key, value, permanent: false);
        expect(
          log,
          contains(
            isMethodCall(
              'addSessionProperty',
              arguments: {'key': key, 'value': value, 'permanent': false},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.addSessionProperty(
            key,
            value,
            permanent: false,
          ),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('removeSessionProperty', () {
      const key = '__key__';
      test('invokes removeSessionProperty method in the method channel',
          () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.removeSessionProperty(key);
        expect(
          log,
          contains(
            isMethodCall(
              'removeSessionProperty',
              arguments: {'key': key},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.removeSessionProperty(key),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('getSessionProperties', () {
      test('invokes getSessionProperties method in the method channel',
          () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        await methodChannelEmbrace.getSessionProperties();
        expect(
          log,
          contains(
            isMethodCall('getSessionProperties', arguments: null),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.getSessionProperties(),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('endSession', () {
      test('invokes endSession method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.endSession(clearUserInfo: false);
        expect(
          log,
          contains(
            isMethodCall('endSession', arguments: {'clearUserInfo': false}),
          ),
        );
      });

      test('clearUserInfo is true by default', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.endSession();
        expect(
          log,
          contains(
            isMethodCall('endSession', arguments: {'clearUserInfo': true}),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.endSession(),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('logInternalError', () {
      const message = '__message__';
      const details = '__details__';
      test('invokes logInternalError method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logInternalError(message, details);
        expect(
          log,
          contains(
            isMethodCall(
              'logInternalError',
              arguments: {'message': message, 'details': details},
            ),
          ),
        );
      });

      test('throws StateError if not started', () {
        expect(
          () => methodChannelEmbrace.logInternalError(message, details),
          throwsA(isA<StateError>()),
        );
        expect(log, isEmpty);
      });
    });

    group('logDartError', () {
      const stack = '__stack__';
      const message = '__message__';
      const context = '__context__';
      const library = '__library__';
      const type = '__type__';

      test('invokes logDartError method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logDartError(stack, message, context, library);
        expect(
          log,
          contains(
            isMethodCall(
              'logDartError',
              arguments: {
                'stack': stack,
                'message': message,
                'context': context,
                'library': library,
                'type': null,
                'wasHandled': false,
              },
            ),
          ),
        );
      });

      test('invokes logDartError method including error type', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        methodChannelEmbrace.logDartError(
          stack,
          message,
          context,
          library,
          errorType: type,
          wasHandled: true,
        );
        expect(
          log,
          contains(
            isMethodCall(
              'logDartError',
              arguments: {
                'stack': stack,
                'message': message,
                'context': context,
                'library': library,
                'type': type,
                'wasHandled': true,
              },
            ),
          ),
        );
      });
    });

    group('getLastRunEndState', () {
      test('invokes getLastRunEndState method in the method channel', () async {
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        await methodChannelEmbrace.getLastRunEndState();
        expect(
          log,
          contains(
            isMethodCall('getLastRunEndState', arguments: null),
          ),
        );
      });

      test('do not throw an error if not started', () async {
        final state = await methodChannelEmbrace.getLastRunEndState();
        expect(state, equals(LastRunEndState.invalid));
      });
    });

    group('handleMethodCall', () {
      setUp(
        () async {
          await methodChannelEmbrace.attachToHostSdk(
            enableIntegrationTesting: false,
          );
        },
      );

      test('logs an internal error for unknown method names', () async {
        const fakeMethodName = '__NotARealMethod__';
        const expectedErrorMessage =
            'Embrace MethodChannel received unknown MethodCall from host SDK.';
        await methodChannelEmbrace.attachToHostSdk(
          enableIntegrationTesting: false,
        );
        log.clear();
        await methodChannelEmbrace
            .handleMethodCall(const MethodCall(fakeMethodName));
        expect(
          log,
          contains(
            isMethodCall(
              'logInternalError',
              arguments: <String, String>{
                'message': expectedErrorMessage,
                'details': fakeMethodName,
              },
            ),
          ),
        );
      });
    });
  });
}
