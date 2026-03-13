import 'package:embrace_platform_interface/http_method.dart';
import 'package:embrace_platform_interface/src/otel/network_request_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('networkRequestAttributes', () {
    test('maps HTTP method to http.request.method', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com/path',
        httpMethod: HttpMethod.get,
        statusCode: 200,
        bytesSent: 0,
        bytesReceived: 512,
      );
      expect(attrs[httpRequestMethod], equals('GET'));
    });

    test('maps url to url.full', () {
      const url = 'https://api.example.com/v1/users';
      final attrs = networkRequestAttributes(
        url: url,
        httpMethod: HttpMethod.post,
        statusCode: 201,
        bytesSent: 128,
        bytesReceived: 64,
      );
      expect(attrs[urlFull], equals(url));
    });

    test('maps statusCode >= 0 to http.response.status_code', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com',
        httpMethod: HttpMethod.get,
        statusCode: 404,
        bytesSent: 0,
        bytesReceived: 0,
      );
      expect(attrs[httpResponseStatusCode], equals('404'));
    });

    test('omits http.response.status_code when statusCode is negative', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com',
        httpMethod: HttpMethod.get,
        statusCode: -1,
        bytesSent: 0,
        bytesReceived: 0,
      );
      expect(attrs.containsKey(httpResponseStatusCode), isFalse);
    });

    test('maps bytesSent >= 0 to http.request.body.size', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com',
        httpMethod: HttpMethod.post,
        statusCode: 200,
        bytesSent: 256,
        bytesReceived: 0,
      );
      expect(attrs[httpRequestBodySize], equals('256'));
    });

    test('omits http.request.body.size when bytesSent is negative', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com',
        httpMethod: HttpMethod.get,
        statusCode: 200,
        bytesSent: -1,
        bytesReceived: 0,
      );
      expect(attrs.containsKey(httpRequestBodySize), isFalse);
    });

    test('maps bytesReceived >= 0 to http.response.body.size', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com',
        httpMethod: HttpMethod.get,
        statusCode: 200,
        bytesSent: 0,
        bytesReceived: 1024,
      );
      expect(attrs[httpResponseBodySize], equals('1024'));
    });

    test('omits http.response.body.size when bytesReceived is negative', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com',
        httpMethod: HttpMethod.get,
        statusCode: 200,
        bytesSent: 0,
        bytesReceived: -1,
      );
      expect(attrs.containsKey(httpResponseBodySize), isFalse);
    });

    test('parses server.address from URL host', () {
      final attrs = networkRequestAttributes(
        url: 'https://api.example.com/v1/users',
        httpMethod: HttpMethod.get,
        statusCode: 200,
        bytesSent: 0,
        bytesReceived: 0,
      );
      expect(attrs[serverAddress], equals('api.example.com'));
    });

    test('omits server.address for URL with empty host', () {
      final attrs = networkRequestAttributes(
        url: '/relative/path',
        httpMethod: HttpMethod.get,
        statusCode: 200,
        bytesSent: 0,
        bytesReceived: 0,
      );
      expect(attrs.containsKey(serverAddress), isFalse);
    });

    test('all OTel attributes present for a completed request', () {
      final attrs = networkRequestAttributes(
        url: 'https://api.example.com/search',
        httpMethod: HttpMethod.post,
        statusCode: 200,
        bytesSent: 100,
        bytesReceived: 500,
      );
      expect(attrs[httpRequestMethod], equals('POST'));
      expect(attrs[urlFull], equals('https://api.example.com/search'));
      expect(attrs[httpResponseStatusCode], equals('200'));
      expect(attrs[httpRequestBodySize], equals('100'));
      expect(attrs[httpResponseBodySize], equals('500'));
      expect(attrs[serverAddress], equals('api.example.com'));
    });

    test('sentinel values (-1) omit size and status attributes', () {
      final attrs = networkRequestAttributes(
        url: 'https://example.com',
        httpMethod: HttpMethod.get,
        statusCode: -1,
        bytesSent: -1,
        bytesReceived: -1,
      );
      expect(attrs.containsKey(httpResponseStatusCode), isFalse);
      expect(attrs.containsKey(httpRequestBodySize), isFalse);
      expect(attrs.containsKey(httpResponseBodySize), isFalse);
    });

    test('supports all HttpMethod values', () {
      for (final method in HttpMethod.values) {
        final attrs = networkRequestAttributes(
          url: 'https://example.com',
          httpMethod: method,
          statusCode: 200,
          bytesSent: 0,
          bytesReceived: 0,
        );
        expect(attrs[httpRequestMethod], equals(method.toHttpString()));
      }
    });
  });
}
