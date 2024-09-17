import 'dart:async';
import 'dart:ui';

import 'package:embrace/embrace_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:flutter/widgets.dart';

export 'package:embrace_platform_interface/http_method.dart' show HttpMethod;
export 'src/http_client.dart';
export 'src/navigation_observer.dart';

@visibleForTesting

/// A variable that can be used to override [Embrace.instance] for
/// mocking in unit tests. If set to a non-null value, [Embrace.instance]
/// will return this instead of its default behavior.
///
/// This **should not** be used in production Flutter code. It is **only**
/// intended to aid in testing.
///
/// ```dart
/// class MockEmbrace extends Mock implements Embrace {}
///
/// void main() {
///   test('mocking embrace instances', () {
///     final mockEmbrace = MockEmbrace();
///     debugEmbraceOverride = mockEmbrace;
///     expect(Embrace.instance, mockEmbrace);
///
///     // You can reset [Embrace.instance] by setting [debugEmbraceOverride] to `null`;
///     debugEmbraceOverride = null
///     expect(Embrace.instance, isNot(mockEmbrace));
///   });
/// }
/// ```
Embrace? debugEmbraceOverride;

/// Entry point for the SDK. This class is part of the Embrace Public API.
class Embrace implements EmbraceFlutterApi {
  // ignore: empty_constructor_bodies
  Embrace._() {}
  EmbracePlatform get _platform => EmbracePlatform.instance;
  static final Embrace _instance = Embrace._();

  /// Entry point for the SDK. Use this to call send logs and other information
  /// to Embrace.
  ///
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () {
  ///     Embrace.instance.addBreadcrumb('Tapped button');
  ///   },
  ///   child: const Text('Add breadcrumb'),
  /// ),
  /// ```
  ///
  /// You can override this value for mocking in unit testing by
  /// setting [debugEmbraceOverride].
  ///
  /// ```dart
  /// class MockEmbrace extends Mock implements Embrace {}
  ///
  /// void main() {
  ///   test('mocking embrace instances', () {
  ///     final mockEmbrace = MockEmbrace();
  ///     debugEmbraceOverride = mockEmbrace;
  ///     expect(Embrace.instance, mockEmbrace);
  ///
  ///     // You can reset [Embrace.instance] by setting [debugEmbraceOverride] to `null`;
  ///     debugEmbraceOverride = null
  ///     expect(Embrace.instance, isNot(mockEmbrace));
  ///   });
  /// }
  /// ```
  static Embrace get instance => debugEmbraceOverride ?? _instance;

  @override
  Future<void> start(
    FutureOr<void> Function() action, {
    bool enableIntegrationTesting = false,
  }) {
    return _start(action, enableIntegrationTesting);
  }

  @override
  void addBreadcrumb(String message) {
    _runCatching(
      'addBreadcrumb',
      () => _platform.addBreadcrumb(message),
    );
  }

  @override
  void logMessage(
    String message,
    Severity severity, {
    Map<String, String>? properties,
  }) {
    switch (severity) {
      case Severity.info:
        logInfo(message, properties: properties);
        break;
      case Severity.warning:
        logWarning(
          message,
          properties: properties,
        );
        break;
      case Severity.error:
        logError(
          message,
          properties: properties,
        );
        break;
    }
  }

  @override
  void logInfo(String message, {Map<String, String>? properties}) {
    _runCatching(
      'logInfo',
      () => _platform.logInfo(message, properties),
    );
  }

  @override
  void logWarning(
    String message, {
    Map<String, String>? properties,
  }) {
    _runCatching(
      'logWarning',
      () => _platform.logWarning(
        message,
        properties,
      ),
    );
  }

  @override
  void logError(
    String message, {
    Map<String, String>? properties,
  }) {
    _runCatching(
      'logError',
      () => _platform.logError(
        message,
        properties,
      ),
    );
  }

  @override
  void recordNetworkRequest(EmbraceNetworkRequest request) {
    _runCatching(
      'recordNetworkRequest',
      () => _platform.logNetworkRequest(
        url: request.url,
        method: request.httpMethod,
        startTime: request.startTime,
        endTime: request.endTime,
        bytesSent: request.bytesSent,
        bytesReceived: request.bytesReceived,
        statusCode: request.statusCode,
        error: request.errorDetails,
        traceId: request.traceId,
        w3cTraceparent: request.w3cTraceparent,
      ),
    );
  }

  @override
  Future<String?> generateW3cTraceparent(String? traceId, String? spanId) {
    return _runCatchingAndReturn<String?>(
      'generateW3cTraceparent',
      () => _platform.generateW3cTraceparent(traceId, spanId),
      defaultValue: null,
    );
  }

  @override
  void logPushNotification(
    String? title,
    String? body, {
    String? subtitle,
    int? badge,
    String? category,
    String? from,
    String? messageId,
    int? priority,
    bool hasNotification = false,
    bool hasData = false,
  }) {
    _runCatching(
      'logPushNotification',
      () => _platform.logPushNotification(
        title: title,
        body: body,
        subtitle: subtitle,
        badge: badge,
        category: category,
        from: from,
        messageId: messageId,
        priority: priority,
        hasNotification: hasNotification,
        hasData: hasData,
      ),
    );
  }

  @override
  void startView(String name) {
    _runCatching(
      'startView',
      () => _platform.startView(name),
    );
  }

  @override
  void endView(String name) {
    _runCatching(
      'endView',
      () => _platform.endView(name),
    );
  }

  @override
  void setUserIdentifier(String id) {
    _runCatching(
      'setUserIdentifier',
      () => _platform.setUserIdentifier(id),
    );
  }

  @override
  void clearUserIdentifier() {
    _runCatching(
      'clearUserIdentifier',
      () => _platform.clearUserIdentifier(),
    );
  }

  @override
  void setUserName(String name) {
    _runCatching(
      'setUserName',
      () => _platform.setUserName(name),
    );
  }

  @override
  void clearUserName() {
    _runCatching(
      'clearUserName',
      () => _platform.clearUserName(),
    );
  }

  @override
  void setUserEmail(String email) {
    _runCatching(
      'setUserEmail',
      () => _platform.setUserEmail(email),
    );
  }

  @override
  void clearUserEmail() {
    _runCatching(
      'clearUserEmail',
      () => _platform.clearUserEmail(),
    );
  }

  @override
  void setUserAsPayer() {
    _runCatching(
      'setUserAsPayer',
      () => _platform.setUserAsPayer(),
    );
  }

  @override
  void clearUserAsPayer() {
    _runCatching(
      'clearUserAsPayer',
      () => _platform.clearUserAsPayer(),
    );
  }

  @override
  void addUserPersona(String persona) {
    _runCatching(
      'addUserPersona',
      () => _platform.addUserPersona(persona),
    );
  }

  @override
  void clearUserPersona(String persona) {
    _runCatching(
      'clearUserPersona',
      () => _platform.clearUserPersona(persona),
    );
  }

  @override
  void clearAllUserPersonas() {
    _runCatching(
      'clearAllUserPersonas',
      () => _platform.clearAllUserPersonas(),
    );
  }

  @override
  void addSessionProperty(String key, String value, {bool permanent = false}) {
    _runCatching(
      'addSessionProperty',
      () => _platform.addSessionProperty(key, value, permanent: permanent),
    );
  }

  @override
  void removeSessionProperty(String key) {
    _runCatching(
      'removeSessionProperty',
      () => _platform.removeSessionProperty(key),
    );
  }

  @override
  void endSession({bool clearUserInfo = true}) {
    return _runCatching(
      'endSession',
      () => _platform.endSession(clearUserInfo: clearUserInfo),
    );
  }

  @override
  Future<String?> getDeviceId() {
    return _platform.getDeviceId();
  }

  @override
  void logDartError(Object error, StackTrace stack) {
    EmbracePlatform.instance.logDartError(
      stack.toString(),
      error.toString(),
      null,
      null,
      errorType: error.runtimeType.toString(),
    );
  }

  @override
  void logHandledDartError(Object error, StackTrace stack) {
    EmbracePlatform.instance.logDartError(
      stack.toString(),
      error.toString(),
      null,
      null,
      errorType: error.runtimeType.toString(),
      wasHandled: true,
    );
  }

  @override
  Future<LastRunEndState> getLastRunEndState() async {
    return _runCatchingAndReturn<LastRunEndState>(
      'getLastRunEndState',
      () => _platform.getLastRunEndState(),
      defaultValue: LastRunEndState.invalid,
    );
  }

  @override
  Future<String?> getCurrentSessionId() async {
    return _runCatchingAndReturn<String?>(
      'getCurrentSessionId',
      () => _platform.getCurrentSessionId(),
      defaultValue: null,
    );
  }

  @override
  Future<EmbraceSpan?> startSpan(
    String name, {
    EmbraceSpan? parent,
    int? startTimeMs,
  }) async {
    return _runCatchingAndReturn<EmbraceSpan?>(
      'startSpan',
      () async {
        final id = await _platform.startSpan(
          name,
          parentSpanId: parent?.id,
          startTimeMs: startTimeMs,
        );
        if (id != null) {
          return Future.value(EmbraceSpanImpl(id, _platform));
        } else {
          return Future.value();
        }
      },
      defaultValue: null,
    );
  }

  @override
  Future<bool> recordCompletedSpan<T>(
    String name,
    int startTimeMs,
    int endTimeMs, {
    ErrorCode? errorCode,
    EmbraceSpan? parent,
    Map<String, String>? attributes,
    List<EmbraceSpanEvent>? events,
  }) async {
    return _runCatchingAndReturn<bool>(
      'recordCompletedSpan',
      () async {
        return _platform.recordCompletedSpan(
          name,
          startTimeMs,
          endTimeMs,
          errorCode: errorCode,
          parentSpanId: parent?.id,
          attributes: attributes,
          events: _convertSpanEvents(events),
        );
      },
      defaultValue: false,
    );
  }
}

List<Map<String, dynamic>>? _convertSpanEvents(List<EmbraceSpanEvent>? events) {
  return events?.map((e) => e.toMap()).toList();
}

/// Runs an action and catches any exception/error. If an exception/error is
/// thrown it will be reported as an internal error to Embrace.
void _runCatching(String message, void Function() action) {
  try {
    action();
  } catch (e) {
    EmbracePlatform.instance.logInternalError(message, e.toString());
  }
}

/// Runs an async function and catches any exception/error.
///
/// If an exception or error is thrown it will be reported as an internal error
/// to Embrace, and the [defaultValue] will be returned.
Future<T> _runCatchingAndReturn<T>(
  String message,
  Future<T> Function() func, {
  required T defaultValue,
}) async {
  try {
    final result = await func();
    return result;
  } catch (e) {
    EmbracePlatform.instance.logInternalError(message, e.toString());
    return defaultValue;
  }
}

Future<void> _start(
  FutureOr<void> Function() action,
  bool enableIntegrationTesting,
) async {
  // step 1 - ensure channels are initialized before calling runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // step 2 - attach to the host SDK
  await EmbracePlatform.instance
      .attachToHostSdk(enableIntegrationTesting: enableIntegrationTesting);

  // step 3 - install a Flutter error handler
  _installFlutterOnError();

  // step 4 - run everything in a Zone & call runApp() supplied by developer
  await _installGlobalErrorHandler(action);
}

/// Installs a Flutter.onError handler to capture uncaught Dart errors/
/// exceptions that originate from within Flutter.
void _installFlutterOnError() {
  // unless a user has explicitly set it to null to ignore errors (which is
  // recommended against), onError should never be null.
  final prevHandler = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails details) {
    _processFlutterError(details);

    if (prevHandler != null) {
      prevHandler(details);
    } else {
      // fallback behavior in the unlikely case onError was set to null.
      FlutterError.presentError(details);
    }
  };
}

/// Installs a guarded zone to capture any uncaught Dart errors/
/// exceptions that originate from outside of the Flutter callstack.
/// https://api.flutter.dev/flutter/dart-async/runZonedGuarded.html
Future<void> _installGlobalErrorHandler(
  FutureOr<void> Function() action,
) async {
  if (_isPlatformDispatcherOnErrorSupported) {
    // We use dynamic to allow compilation in versions below Flutter 3.1
    // where this method is not available
    // ignore: avoid_dynamic_calls
    (PlatformDispatcher.instance as dynamic).onError =
        (Object exception, StackTrace stackTrace) {
      _processGlobalZoneError(exception, stackTrace);
      return false;
    };
    await action();
  } else {
    runZonedGuarded<void>(
      () async {
        await action();
      },
      _processGlobalZoneError,
    );
  }
}

// PlatformDispatcher.onError is only available for Flutter 3.1 and above
// To check if it is supported, onError is called to a dynamic variable and
// if it returns an error this method does not exits
bool get _isPlatformDispatcherOnErrorSupported {
  try {
    // We use dynamic to allow compilation in versions below Flutter 3.1
    // where this method is not available.
    // When dynamic, if it is not available it will throw a NoSuchMethodError
    // ignore: avoid_dynamic_calls, unnecessary_statements
    (PlatformDispatcher.instance as dynamic).onError;
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    return false;
  }
  return true;
}

/// Processes an error caught in Flutter.onError.
void _processFlutterError(FlutterErrorDetails details) {
  EmbracePlatform.instance.logDartError(
    details.stack?.toString(),
    details.summary.toString(),
    details.context?.toString(),
    details.library,
    errorType: details.exception.runtimeType.toString(),
  );
}

/// Processes an error caught in Embrace's global zone.
void _processGlobalZoneError(Object error, StackTrace stack) {
  EmbracePlatform.instance.logDartError(
    stack.toString(),
    error.toString(),
    null,
    null,
    errorType: error.runtimeType.toString(),
  );
}

/// Implementation detail of EmbraceSpan. You should
/// not use this directly as function signatures may change without warning.
class EmbraceSpanImpl extends EmbraceSpan {
  /// Constructor
  EmbraceSpanImpl(String id, this._platform) : super(id);

  final EmbracePlatform _platform;

  @override
  Future<bool> stop({
    ErrorCode? errorCode,
    int? endTimeMs,
  }) {
    return _platform.stopSpan(id, errorCode: errorCode, endTimeMs: endTimeMs);
  }

  @override
  Future<bool> addEvent(
    String name, {
    int? timestampMs,
    Map<String, String>? attributes,
  }) {
    return _platform.addSpanEvent(
      id,
      name,
      timestampMs: timestampMs,
      attributes: attributes,
    );
  }

  @override
  Future<bool> addAttribute(String key, String value) {
    return _platform.addSpanAttribute(id, key, value);
  }
}
