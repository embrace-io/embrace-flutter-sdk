import 'package:embrace/embrace.dart';
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
    try {
      final response = await _internalClient.send(request);
      final end = DateTime.now();
      final isSuccess = (response.statusCode ~/ 100) == 2;

      // ignore: deprecated_member_use_from_same_package
      Embrace.instance.logNetworkRequest(
        url: request.url.toString(),
        method: method,
        startTime: start.millisecondsSinceEpoch,
        endTime: end.millisecondsSinceEpoch,
        bytesSent: request.contentLength ?? 0,
        bytesReceived: response.contentLength ?? 0,
        statusCode: response.statusCode,
        error: isSuccess ? null : response.reasonPhrase,
      );
      return response;
    } on ClientException catch (e) {
      final end = DateTime.now();
      // ignore: deprecated_member_use_from_same_package
      Embrace.instance.logNetworkRequest(
        url: request.url.toString(),
        method: method,
        startTime: start.millisecondsSinceEpoch,
        endTime: end.millisecondsSinceEpoch,
        bytesSent: request.contentLength ?? 0,
        bytesReceived: 0,
        statusCode: 0,
        error: e.message,
      );
      rethrow;
    }
  }

  @override
  void close() => _internalClient.close();
}
