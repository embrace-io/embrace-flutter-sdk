import 'dart:convert';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:dio/dio.dart';
import 'package:embrace/embrace.dart';
import 'package:embrace_dio/embrace_dio.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

class MockClientAdapter extends Mock implements HttpClientAdapter {}

class MockRequestOptions extends Mock implements RequestOptions {}

class IsRecentTimestamp extends Matcher {
  @override
  // ignore: strict_raw_type
  bool matches(Object? timestamp, Map matchState) {
    if (timestamp == null || timestamp is! int) {
      return false;
    }
    return (DateTime.now().millisecondsSinceEpoch - timestamp) < 60 * 1000;
  }

  @override
  Description describe(Description description) {
    return description
        .add('The timestamp must be less than 60 seconds into the past.');
  }
}

void main() {
  final _dio = Dio();
  late EmbracePlatform _embracePlatform;
  late MockClientAdapter _mockAdapter;
  final _isRecentTimestamp = IsRecentTimestamp();

  setUpAll(() {
    registerFallbackValue(MockRequestOptions());
    _embracePlatform = MockEmbracePlatform();
    EmbracePlatform.instance = _embracePlatform;
    _mockAdapter = MockClientAdapter();
    _dio.httpClientAdapter = _mockAdapter;
    _dio.interceptors.add(EmbraceInterceptor());
  });

  setUp(() {
    reset(_embracePlatform);
    reset(_mockAdapter);
  });

  void mockSuccessfulAnswer() {
    final httpResponse = ResponseBody.fromString(
      jsonEncode({'result': 'this is the result'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

    when(() => _mockAdapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => httpResponse);
  }

  void mockFailedAnswer() {
    when(() => _mockAdapter.fetch(any(), any(), any()))
        .thenThrow(Exception('Request failed'));
  }

  void mockHttpErrorAnswer(int statusCode) {
    final httpResponse = ResponseBody.fromString(
      '',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
    when(() => _mockAdapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => httpResponse);
  }

  void verifySuccesfulHttpRequest(
    HttpMethod httpMethod,
    int bytesSent,
    int bytesReceived,
  ) {
    verify(
      () => _embracePlatform.logNetworkRequest(
        url: '/test_url',
        method: httpMethod,
        startTime: any(named: 'startTime', that: _isRecentTimestamp),
        endTime: any(named: 'endTime', that: _isRecentTimestamp),
        bytesSent: bytesSent,
        bytesReceived: bytesReceived,
        statusCode: 200,
      ),
    ).called(1);
  }

  void verifyFailedHttpRequest(HttpMethod httpMethod) {
    verify(
      () => _embracePlatform.logNetworkRequest(
        url: '/test_url',
        method: httpMethod,
        startTime: any(named: 'startTime', that: _isRecentTimestamp),
        endTime: any(named: 'endTime', that: _isRecentTimestamp),
        bytesSent: -1,
        bytesReceived: -1,
        statusCode: -1,
        error: any(named: 'error'),
      ),
    ).called(1);
  }

  group('GET requests', () {
    test('Succesful GET request with text result', () async {
      final httpResponse = ResponseBody.fromString(
        'The mock request has completed succesfully',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
        },
      );

      when(() => _mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((_) async => httpResponse);

      // ignore: inference_failure_on_function_invocation
      await _dio.get('/test_url');

      verifySuccesfulHttpRequest(HttpMethod.get, 0, 42);
    });
    test('Succesful GET request with JSON result', () async {
      mockSuccessfulAnswer();

      // ignore: inference_failure_on_function_invocation
      await _dio.get('/test_url');

      verifySuccesfulHttpRequest(HttpMethod.get, 0, 28);
    });
    test('Succesful GET request with empty result', () async {
      final httpResponse = ResponseBody.fromString(
        '',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
        },
      );

      when(() => _mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((_) async => httpResponse);

      // ignore: inference_failure_on_function_invocation
      await _dio.get('/test_url');

      verifySuccesfulHttpRequest(HttpMethod.get, 0, 0);
    });
    test('Unsuccesful GET request', () async {
      mockFailedAnswer();

      try {
        // ignore: inference_failure_on_function_invocation
        await _dio.get('/test_url');
      } catch (dioError) {
        // The error is expected
      }

      verifyFailedHttpRequest(HttpMethod.get);
    });
    test('GET request with 401 response records status code', () async {
      mockHttpErrorAnswer(401);

      try {
        // ignore: inference_failure_on_function_invocation
        await _dio.get('/test_url');
      } catch (dioError) {
        // The error is expected
      }

      verify(
        () => _embracePlatform.logNetworkRequest(
          url: '/test_url',
          method: HttpMethod.get,
          startTime: any(named: 'startTime', that: _isRecentTimestamp),
          endTime: any(named: 'endTime', that: _isRecentTimestamp),
          bytesSent: 0,
          bytesReceived: 0,
          statusCode: 401,
        ),
      ).called(1);
    });
    test('GET request with 500 response records status code', () async {
      mockHttpErrorAnswer(500);

      try {
        // ignore: inference_failure_on_function_invocation
        await _dio.get('/test_url');
      } catch (dioError) {
        // The error is expected
      }

      verify(
        () => _embracePlatform.logNetworkRequest(
          url: '/test_url',
          method: HttpMethod.get,
          startTime: any(named: 'startTime', that: _isRecentTimestamp),
          endTime: any(named: 'endTime', that: _isRecentTimestamp),
          bytesSent: 0,
          bytesReceived: 0,
          statusCode: 500,
        ),
      ).called(1);
    });
  });

  group('POST requests', () {
    test('Succesful POST request with JSON result', () async {
      mockSuccessfulAnswer();

      final body = {'param': 'this is a param in the POST body'};
      // ignore: inference_failure_on_function_invocation
      await _dio.post(
        '/test_url',
        data: json.encode(body),
      );

      verifySuccesfulHttpRequest(HttpMethod.post, 44, 28);
    });
    test('Successful POST request with Map body calculates bytesSent',
        () async {
      mockSuccessfulAnswer();

      final body = {'param': 'this is a param in the POST body'};
      // ignore: inference_failure_on_function_invocation
      await _dio.post('/test_url', data: body);

      verifySuccesfulHttpRequest(HttpMethod.post, 44, 28);
    });
    test('Unsuccesful POST request', () async {
      mockFailedAnswer();

      try {
        // ignore: inference_failure_on_function_invocation
        await _dio.post('/test_url');
      } catch (dioError) {
        // The error is expected
      }

      verifyFailedHttpRequest(HttpMethod.post);
    });
  });

  group('PUT requests', () {
    test('Succesful PUT request with JSON result', () async {
      mockSuccessfulAnswer();

      final body = {'param': 'this is a param in the PUT body'};
      // ignore: inference_failure_on_function_invocation
      await _dio.put(
        '/test_url',
        data: json.encode(body),
      );

      verifySuccesfulHttpRequest(HttpMethod.put, 43, 28);
    });
    test('Unsuccesful PUT request', () async {
      mockFailedAnswer();

      try {
        // ignore: inference_failure_on_function_invocation
        await _dio.put('/test_url');
      } catch (dioError) {
        // The error is expected
      }

      verifyFailedHttpRequest(HttpMethod.put);
    });
  });

  group('DELETE requests', () {
    test('Succesful DELETE request with JSON result', () async {
      mockSuccessfulAnswer();

      // ignore: inference_failure_on_function_invocation
      await _dio.delete('/test_url');

      verifySuccesfulHttpRequest(HttpMethod.delete, 0, 28);
    });
    test('Unsuccesful DELETE request', () async {
      mockFailedAnswer();

      try {
        // ignore: inference_failure_on_function_invocation
        await _dio.delete('/test_url');
      } catch (dioError) {
        // The error is expected
      }

      verifyFailedHttpRequest(HttpMethod.delete);
    });
  });

  group('OTel traceparent injection', () {
    late MockEmbracePlatform platform;
    late MockClientAdapter mockAdapter;
    late Dio dio;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      platform = MockEmbracePlatform();
      EmbracePlatform.instance = platform;
      when(
        () => platform.attachToHostSdk(
          enableIntegrationTesting: any(named: 'enableIntegrationTesting'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => platform.startSpan(
          any(),
          parentSpanId: any(named: 'parentSpanId'),
          startTimeMs: any(named: 'startTimeMs'),
        ),
      ).thenAnswer((_) async => 'test-span-id');
      when(
        () => platform.stopSpan(any(), endTimeMs: any(named: 'endTimeMs')),
      ).thenAnswer((_) async => true);

      await Embrace.instance.start();

      mockAdapter = MockClientAdapter();
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          '',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.textPlainContentType],
          },
        ),
      );
      dio = Dio()
        ..httpClientAdapter = mockAdapter
        ..interceptors.add(EmbraceInterceptor());
    });

    // ignore: invalid_use_of_visible_for_testing_member
    tearDown(OTelAPI.reset);

    test('injects traceparent when OTel span is active', () async {
      final tracer = OTelAPI.tracerProvider().getTracer('test');
      final span = tracer.startSpan('test');

      // ignore: inference_failure_on_function_invocation
      await dio.get('/test_url');

      verify(
        () => platform.logNetworkRequest(
          url: '/test_url',
          method: HttpMethod.get,
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
      // ignore: inference_failure_on_function_invocation
      await dio.get('/test_url');

      verify(
        () => platform.logNetworkRequest(
          url: '/test_url',
          method: HttpMethod.get,
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

      // ignore: inference_failure_on_function_invocation
      await dio.get('/test_url');

      verify(
        () => platform.logNetworkRequest(
          url: '/test_url',
          method: HttpMethod.get,
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
}
