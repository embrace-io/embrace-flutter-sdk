import 'package:embrace_platform_interface/http_method.dart';

/// Returns OTel HTTP semantic convention attributes for a network request.
///
/// - [url]: the full URL of the request; used for [urlFull] and to parse
///   [serverAddress]
/// - [httpMethod]: the HTTP method; mapped to [httpRequestMethod]
/// - [statusCode]: HTTP status code; values < 0 are treated as unavailable
///   and omitted from the result
/// - [bytesSent]: request body size in bytes; values < 0 are omitted
/// - [bytesReceived]: response body size in bytes; values < 0 are omitted
///
/// Returns a [Map<String, String>] keyed by OTel semantic convention
/// attribute names, suitable for use with `attributesFromMap` or
/// `ReadableSpanData.fromRaw`.
Map<String, String> networkRequestAttributes({
  required String url,
  required HttpMethod httpMethod,
  required int statusCode,
  required int bytesSent,
  required int bytesReceived,
}) {
  final attrs = <String, String>{
    httpRequestMethod: httpMethod.toHttpString(),
    urlFull: url,
  };

  if (statusCode >= 0) {
    attrs[httpResponseStatusCode] = statusCode.toString();
  }
  if (bytesSent >= 0) {
    attrs[httpRequestBodySize] = bytesSent.toString();
  }
  if (bytesReceived >= 0) {
    attrs[httpResponseBodySize] = bytesReceived.toString();
  }

  try {
    final host = Uri.parse(url).host;
    if (host.isNotEmpty) {
      attrs[serverAddress] = host;
    }
  } catch (_) {
    // Malformed URL — server.address is omitted
  }

  return attrs;
}

/// OTel semantic convention key: HTTP request method (e.g. `"GET"`).
const String httpRequestMethod = 'http.request.method';

/// OTel semantic convention key: full URL of the request.
const String urlFull = 'url.full';

/// OTel semantic convention key: HTTP response status code.
const String httpResponseStatusCode = 'http.response.status_code';

/// OTel semantic convention key: HTTP request body size in bytes.
const String httpRequestBodySize = 'http.request.body.size';

/// OTel semantic convention key: HTTP response body size in bytes.
const String httpResponseBodySize = 'http.response.body.size';

/// OTel semantic convention key: server host name or IP address.
const String serverAddress = 'server.address';
