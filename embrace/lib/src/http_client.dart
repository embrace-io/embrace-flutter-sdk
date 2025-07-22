import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:embrace_platform_interface/http_method.dart';
import 'package:http/http.dart';

/// {@template embrace_http_client}
/// A [Client] that automatically logs http requests to Embrace.
///
/// ```dart
/// void main() async {
///   final client = EmbraceHttpClient();
///   final response = client.get(Uri.parse('https://embrace.io'));
///   print(response.body);
/// }
/// ```
///
/// This can also be used with existing [Client]s to add in Embrace's logging
/// functionality. For example:
///
/// ```dart
/// void main() async {
///   final baseClient = MyCustomClient();
///   final client = EmbraceHttpClient(innerClient: baseClient);
///   final response = client.get(Uri.parse('https://embrace.io'));
///   print(response.body);
/// }
/// ```
///
/// Be sure to close your client when it's no longer needed by calling
/// `client.close()`.
/// {@endtemplate}
class EmbraceHttpClient extends BaseClient {
  /// {@macro embrace_http_client}
  EmbraceHttpClient({
    Client? internalClient,
  }) : _internalClient = internalClient ?? Client();

  final Client _internalClient;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final start = DateTime.now();
    final method = httpMethodFromString(request.method);

    final w3cTraceparent = request.headers['traceparent'] ??
        await Embrace.instance.generateW3cTraceparent(
          null,
          null,
        );
    if (w3cTraceparent != null) {
      request.headers.putIfAbsent('traceparent', () => w3cTraceparent);
    }

    try {
      final response = await _internalClient.send(request);
      final end = DateTime.now();

      Embrace.instance.recordNetworkRequest(
        EmbraceNetworkRequest.fromCompletedRequest(
          url: request.url.toString(),
          httpMethod: method,
          startTime: start.millisecondsSinceEpoch,
          endTime: end.millisecondsSinceEpoch,
          bytesSent: request.contentLength ?? 0,
          bytesReceived: response.contentLength ?? 0,
          statusCode: response.statusCode,
          w3cTraceparent: w3cTraceparent,
        ),
      );
      return response;
    } on ClientException catch (e) {
      final end = DateTime.now();

      Embrace.instance.recordNetworkRequest(
        EmbraceNetworkRequest.fromIncompleteRequest(
          url: request.url.toString(),
          httpMethod: method,
          startTime: start.millisecondsSinceEpoch,
          endTime: end.millisecondsSinceEpoch,
          errorDetails: e.message,
          w3cTraceparent: w3cTraceparent,
        ),
      );
      rethrow;
    }
  }

  @override
  void close() => _internalClient.close();
}
