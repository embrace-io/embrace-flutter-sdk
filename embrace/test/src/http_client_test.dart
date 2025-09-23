import 'package:embrace/embrace.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

class MockClient extends Mock implements Client {}

class MockStreamedResponse extends Mock implements StreamedResponse {}

class MockBaseRequest extends Mock implements BaseRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockBaseRequest());
    registerFallbackValue(HttpMethod.patch);
  });
  group('EmbraceClient', () {
    late EmbracePlatform embracePlatform;
    late Client client;
    late StreamedResponse response;

    setUp(() {
      embracePlatform = MockEmbracePlatform();
      EmbracePlatform.instance = embracePlatform;

      client = MockClient();
      response = MockStreamedResponse();
      when(() => client.send(any())).thenAnswer((_) async => response);

      when(() => response.stream).thenAnswer((_) => ByteStream.fromBytes([]));
      when(() => response.headers).thenReturn({});
      when(() => response.isRedirect).thenReturn(false);
      when(() => response.persistentConnection).thenReturn(false);
    });

    test('can be created without causing errors to be throw', () {
      expect(EmbraceHttpClient(), isA<EmbraceHttpClient>());
    });

    test('logs network request', () async {
      const url = 'https://embrace.io';
      const statusCode = 200;

      when(() => response.statusCode).thenReturn(statusCode);

      final embraceClient = EmbraceHttpClient(internalClient: client);
      await embraceClient.get(Uri.parse(url));

      verify(
        () => embracePlatform.logNetworkRequest(
          url: url,
          method: HttpMethod.get,
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          bytesSent: any(named: 'bytesSent'),
          bytesReceived: any(named: 'bytesReceived'),
          statusCode: statusCode,
        ),
      ).called(1);
    });

    test('uses HttpMethod.other when http method is invalid', () async {
      when(() => response.statusCode).thenReturn(200);

      final embraceClient = EmbraceHttpClient(internalClient: client);

      await embraceClient.send(
        Request('TESTING', Uri.parse('https://embrace.io')),
      );

      verify(
        () => embracePlatform.logNetworkRequest(
          url: any(named: 'url'),
          method: HttpMethod.other,
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          bytesSent: any(named: 'bytesSent'),
          bytesReceived: any(named: 'bytesReceived'),
          statusCode: any(named: 'statusCode'),
        ),
      ).called(1);
    });

    test('logs network error if ClientException is thrown', () async {
      const errorMessage = '__error__';
      when(() => client.send(any())).thenThrow(ClientException(errorMessage));

      final embraceClient = EmbraceHttpClient(internalClient: client);

      await expectLater(
        () async =>
            embraceClient.send(Request('GET', Uri.parse('https://embrace.io'))),
        throwsA(isA<ClientException>()),
      );

      verify(
        () => embracePlatform.logNetworkRequest(
          url: any(named: 'url'),
          method: any(named: 'method'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          bytesSent: -1,
          bytesReceived: -1,
          statusCode: -1,
          error: errorMessage,
        ),
      ).called(1);
    });

    test('.close() closes internal client without errors', () {
      EmbraceHttpClient(internalClient: client).close();
      verify(() => client.close()).called(1);
    });
  });
}
