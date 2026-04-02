import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
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

    group('OTel traceparent injection', () {
      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        when(
          () => embracePlatform.attachToHostSdk(
            enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => embracePlatform.startSpan(
            any(),
            parentSpanId: any(named: 'parentSpanId'),
            startTimeMs: any(named: 'startTimeMs'),
          ),
        ).thenAnswer((_) async => 'test-span-id');
        when(
          () => embracePlatform.stopSpan(
            any(),
            endTimeMs: any(named: 'endTimeMs'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => embracePlatform.generateW3cTraceparent(any(), any()),
        ).thenAnswer((_) async => null);
        await Embrace.instance.start();
      });

      // ignore: invalid_use_of_visible_for_testing_member
      tearDown(OTelAPI.reset);

      test('injects traceparent when OTel span is active', () async {
        final tracer = OTelAPI.tracerProvider().getTracer('test');
        final span = tracer.startSpan('test');

        when(() => response.statusCode).thenReturn(200);
        final embraceClient = EmbraceHttpClient(internalClient: client);
        await embraceClient.get(Uri.parse('https://embrace.io'));

        verify(
          () => embracePlatform.logNetworkRequest(
            url: any(named: 'url'),
            method: any(named: 'method'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            bytesSent: any(named: 'bytesSent'),
            bytesReceived: any(named: 'bytesReceived'),
            statusCode: any(named: 'statusCode'),
            w3cTraceparent: any(named: 'w3cTraceparent', that: isNotNull),
          ),
        ).called(1);

        span.end();
      });

      test('does not inject traceparent when no span is active', () async {
        when(() => response.statusCode).thenReturn(200);
        final embraceClient = EmbraceHttpClient(internalClient: client);
        await embraceClient.get(Uri.parse('https://embrace.io'));

        verify(
          () => embracePlatform.logNetworkRequest(
            url: any(named: 'url'),
            method: any(named: 'method'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            bytesSent: any(named: 'bytesSent'),
            bytesReceived: any(named: 'bytesReceived'),
            statusCode: any(named: 'statusCode'),
            w3cTraceparent: any(named: 'w3cTraceparent', that: isNull),
          ),
        ).called(1);
      });

      test('traceparent header value matches active span traceId and spanId',
          () async {
        final tracer = OTelAPI.tracerProvider().getTracer('test');
        final span = tracer.startSpan('test');
        final sc = span.spanContext;
        final flags = sc.traceFlags.asByte.toRadixString(16).padLeft(2, '0');
        final expected =
            '00-${sc.traceId.hexString}-${sc.spanId.hexString}-$flags';

        when(() => response.statusCode).thenReturn(200);
        final embraceClient = EmbraceHttpClient(internalClient: client);
        await embraceClient.get(Uri.parse('https://embrace.io'));

        verify(
          () => embracePlatform.logNetworkRequest(
            url: any(named: 'url'),
            method: any(named: 'method'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            bytesSent: any(named: 'bytesSent'),
            bytesReceived: any(named: 'bytesReceived'),
            statusCode: any(named: 'statusCode'),
            w3cTraceparent: expected,
          ),
        ).called(1);

        span.end();
      });
    });
  });
}
