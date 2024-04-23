import 'dart:convert';
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
}
