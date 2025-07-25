import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/http_method.dart';

/// To have the Embrace SDK automatically capture Dio network requests, add
/// the Embrace interceptor to your Dio instance, like this:
/// ```dart
/// var dio = Dio();
/// dio.interceptors.add(EmbraceInterceptor());
/// ```
class EmbraceInterceptor extends Interceptor {
  static const String _contentLengthHeaderName = 'Content-Length';
  final _startTimes = HashMap<RequestOptions, int>();

  @override
  // ignore: avoid_void_async, strict_raw_type
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _startTimes[options] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  // ignore: avoid_void_async, strict_raw_type
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      final request = response.requestOptions;
      final url = request.uri.toString();
      final method = httpMethodFromString(request.method);
      final startTime = _startTimes[request] ?? 0;
      final endTime = DateTime.now().millisecondsSinceEpoch;
      var bytesSent = 0;
      final w3cTraceparent = await _addTraceparentHeader(request);

      if (request.data is String) {
        bytesSent = (request.data as String).length;
      }
      var bytesReceived = 0;
      final header = response.headers.value(_contentLengthHeaderName);
      if (header != null) {
        try {
          bytesReceived = int.parse(header);
        } catch (formatException) {
          EmbracePlatform.instance.logInternalError(
            'Could not parse Content-Length header',
            formatException.toString(),
          );
        }
      } else {
        if (response.data != null) {
          if (request.responseType == ResponseType.plain ||
              request.responseType == ResponseType.json) {
            bytesReceived = response.data.toString().length;
          }
        }
      }
      Embrace.instance.recordNetworkRequest(
        EmbraceNetworkRequest.fromCompletedRequest(
          url: url,
          httpMethod: method,
          startTime: startTime,
          endTime: endTime,
          bytesSent: bytesSent,
          bytesReceived: bytesReceived,
          statusCode: response.statusCode ?? 0,
          w3cTraceparent: w3cTraceparent,
        ),
      );
    } catch (e) {
      EmbracePlatform.instance
          .logInternalError('Could not capture network request', e.toString());
    } finally {
      handler.next(response);
    }
  }

  @override
  // ignore: avoid_void_async, strict_raw_type, deprecated_member_use
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    try {
      final request = err.requestOptions;
      final url = request.uri.toString();
      final method = httpMethodFromString(request.method);
      final startTime = _startTimes[request] ?? 0;
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final w3cTraceparent = await _addTraceparentHeader(request);

      Embrace.instance.recordNetworkRequest(
        EmbraceNetworkRequest.fromIncompleteRequest(
          url: url,
          httpMethod: method,
          startTime: startTime,
          endTime: endTime,
          errorDetails: err.message?.toString() ?? '',
          w3cTraceparent: w3cTraceparent,
        ),
      );
    } catch (e) {
      EmbracePlatform.instance
          .logInternalError('Could not capture network error', e.toString());
    } finally {
      handler.next(err);
    }
  }

  Future<String?> _addTraceparentHeader(
    RequestOptions options,
  ) async {
    final w3cTraceparent = options.headers['traceparent']?.toString() ??
        await Embrace.instance.generateW3cTraceparent(
          null,
          null,
        );
    if (w3cTraceparent != null) {
      options.headers.putIfAbsent('traceparent', () => w3cTraceparent);
    }
    return w3cTraceparent;
  }
}
