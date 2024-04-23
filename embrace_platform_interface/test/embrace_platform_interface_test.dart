import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/http_method.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class EmbraceMock extends EmbracePlatform {}

class EmbraceImplementerMock extends Mock implements EmbracePlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('EmbracePlatformInterface', () {
    late EmbracePlatform embracePlatform;

    setUp(() {
      embracePlatform = EmbraceMock();
    });

    test('getting instance returns a EmbracePlatform', () {
      expect(EmbracePlatform.instance, isA<EmbracePlatform>());
    });

    test('setting instance sets the instance', () {
      EmbracePlatform.instance = embracePlatform;
      expect(EmbracePlatform.instance, embracePlatform);
    });

    test(
        'setting instance fails if class implements '
        'EmbracePlatform instead of extending it', () {
      final implementerEmbracePlatform = EmbraceImplementerMock();

      expect(
        () => EmbracePlatform.instance = implementerEmbracePlatform,
        throwsA(anything),
      );
    });

    test('isStarted throws an UnimplementedError', () {
      expect(
        () => embracePlatform.isStarted,
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('attachToHostSdk throws an UnimplementedError', () {
      expect(
        () => embracePlatform.attachToHostSdk(enableIntegrationTesting: true),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('endAppStartup throws an UnimplementedError', () {
      expect(
        () => embracePlatform.endAppStartup({}),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('logBreadcrumb throws an UnimplementedError', () {
      expect(
        () => embracePlatform.logBreadcrumb('__message__ '),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('addBreadcrumb throws an UnimplementedError', () {
      expect(
        () => embracePlatform.addBreadcrumb('__message__ '),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('logInfo throws an UnimplementedError', () {
      expect(
        () => embracePlatform.logInfo('__message__ ', {}),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('logWarning throws an UnimplementedError', () {
      expect(
        () => embracePlatform.logWarning(
          '__message__ ',
          {},
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('logError throws an UnimplementedError', () {
      expect(
        () => embracePlatform.logError(
          '__message__ ',
          {},
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('logNetworkRequest throws an UnimplementedError', () {
      expect(
        () => embracePlatform.logNetworkRequest(
          url: '__url__',
          method: HttpMethod.get,
          startTime: 1234,
          endTime: 4321,
          bytesSent: 222,
          bytesReceived: 444,
          statusCode: 200,
          error: '__error__',
          traceId: '__trace__',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('startView throws an UnimplementedError', () {
      expect(
        () => embracePlatform.startView('__name__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('endView throws an UnimplementedError', () {
      expect(
        () => embracePlatform.endView('__name__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('startMoment throws an UnimplementedError', () {
      expect(
        () => embracePlatform.startMoment(
          '__name__',
          '__identifier__',
          {},
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('endMoment throws an UnimplementedError', () {
      expect(
        () => embracePlatform.endMoment(
          '__name__',
          '__identifier__',
          {},
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('getDeviceId throws an UnimplementedError', () {
      expect(
        () => embracePlatform.getDeviceId(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('triggerNativeSdkError throws an UnimplementedError', () {
      expect(
        () => embracePlatform.triggerNativeSdkError(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('triggerAnr throws an UnimplementedError', () {
      expect(
        () => embracePlatform.triggerAnr(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('triggerRaisedSignal throws an UnimplementedError', () {
      expect(
        () => embracePlatform.triggerRaisedSignal(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('triggerMethodChannelError throws an UnimplementedError', () {
      expect(
        () => embracePlatform.triggerMethodChannelError(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('setUserIdentifier throws an UnimplementedError', () {
      expect(
        () => embracePlatform.setUserIdentifier('__id__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('clearUserIdentifier throws an UnimplementedError', () {
      expect(
        () => embracePlatform.clearUserIdentifier(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('setUserName throws an UnimplementedError', () {
      expect(
        () => embracePlatform.setUserName('__name__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('clearUserName throws an UnimplementedError', () {
      expect(
        () => embracePlatform.clearUserName(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('setUserEmail throws an UnimplementedError', () {
      expect(
        () => embracePlatform.setUserEmail('__email__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('clearUserEmail throws an UnimplementedError', () {
      expect(
        () => embracePlatform.clearUserEmail(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('setUserAsPayer throws an UnimplementedError', () {
      expect(
        () => embracePlatform.setUserAsPayer(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('clearUserAsPayer throws an UnimplementedError', () {
      expect(
        () => embracePlatform.clearUserAsPayer(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('addUserPersona throws an UnimplementedError', () {
      expect(
        () => embracePlatform.addUserPersona('__persona__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('clearUserPersona throws an UnimplementedError', () {
      expect(
        () => embracePlatform.clearUserPersona('__persona__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('clearAllUserPersonas throws an UnimplementedError', () {
      expect(
        () => embracePlatform.clearAllUserPersonas(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('addSessionProperty throws an UnimplementedError', () {
      expect(
        () => embracePlatform.addSessionProperty(
          'key',
          'value',
          permanent: false,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('removeSessionProperty throws an UnimplementedError', () {
      expect(
        () => embracePlatform.removeSessionProperty('key'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('getSessionProperties throws an UnimplementedError', () {
      expect(
        () => embracePlatform.getSessionProperties(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('endSession throws an UnimplementedError', () {
      expect(
        () => embracePlatform.endSession(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('logInternalError throws an UnimplementedError', () {
      expect(
        () => embracePlatform.logInternalError('__message__', '__details__'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('logDartError throws an UnimplementedError', () {
      expect(
        () => embracePlatform.logDartError(
          '__stack__',
          '__message__',
          '__context__',
          '__library__',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('getLastRunEndState throws an UnimplementedError', () {
      expect(
        () => embracePlatform.getLastRunEndState(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
