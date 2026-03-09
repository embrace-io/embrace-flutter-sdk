import 'dart:async';
import 'dart:ui';

import 'package:embrace/embrace_api.dart';
import 'package:embrace/src/otel/embrace_span_processor.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:embrace_platform_interface/otel.dart';
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
  _LifecycleObserver? _lifecycleObserver;

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

  EmbraceSpanProcessor? _spanProcessor;

  @override
  Future<void> start({
    FutureOr<void> Function()? action,
    @Deprecated(
      'This parameter is obsolete and will be removed in a future release.',
    )
    bool enableIntegrationTesting = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    await EmbracePlatform.instance.attachToHostSdk(
      enableIntegrationTesting: enableIntegrationTesting,
    );

    _lifecycleObserver = _LifecycleObserver(_onAppDetached);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    _spanProcessor = EmbraceSpanProcessor();

    if (action != null) {
      await _installErrorHandlers(action);
    }
  }

  void _onAppDetached() {
    _spanProcessor?.shutdown();
  }

  /// The span processor created during [start], or null before start is called.
  ///
  /// For testing only.
  @visibleForTesting
  EmbraceSpanProcessor? get spanProcessorForTesting => _spanProcessor;

  /// Overrides the span processor for testing.
  ///
  /// For testing only — inject a pre-configured processor to verify wiring.
  @visibleForTesting
  set spanProcessorForTesting(EmbraceSpanProcessor? processor) {
    _spanProcessor = processor;
  }

  /// Shuts down the span processor and removes the lifecycle observer.
  ///
  /// For testing only — call in tearDown to clean up singleton state.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _spanProcessor?.shutdown();
    _spanProcessor = null;
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      _lifecycleObserver = null;
    }
  }

  @override
  Future<void> installErrorHandlers(FutureOr<void> Function() action) {
    return _installErrorHandlers(action);
  }

  @override
  void addBreadcrumb(String message) {
    _runCatching('addBreadcrumb', () => _platform.addBreadcrumb(message));
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
        logWarning(message, properties: properties);
        break;
      case Severity.error:
        logError(message, properties: properties);
        break;
    }
  }

  @override
  void logInfo(String message, {Map<String, String>? properties}) {
    _runCatching('logInfo', () => _platform.logInfo(message, properties));
  }

  @override
  void logWarning(String message, {Map<String, String>? properties}) {
    _runCatching('logWarning', () => _platform.logWarning(message, properties));
  }

  @override
  void logError(String message, {Map<String, String>? properties}) {
    _runCatching('logError', () => _platform.logError(message, properties));
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
    _runCatching('startView', () => _platform.startView(name));
  }

  @override
  void endView(String name) {
    _runCatching('endView', () => _platform.endView(name));
  }

  @override
  void setUserIdentifier(String id) {
    _runCatching('setUserIdentifier', () => _platform.setUserIdentifier(id));
  }

  @override
  void clearUserIdentifier() {
    _runCatching('clearUserIdentifier', () => _platform.clearUserIdentifier());
  }

  @override
  void setUserName(String name) {
    _runCatching('setUserName', () => _platform.setUserName(name));
  }

  @override
  void clearUserName() {
    _runCatching('clearUserName', () => _platform.clearUserName());
  }

  @override
  void setUserEmail(String email) {
    _runCatching('setUserEmail', () => _platform.setUserEmail(email));
  }

  @override
  void clearUserEmail() {
    _runCatching('clearUserEmail', () => _platform.clearUserEmail());
  }

  @override
  void setUserAsPayer() {
    _runCatching('setUserAsPayer', () => _platform.setUserAsPayer());
  }

  @override
  void clearUserAsPayer() {
    _runCatching('clearUserAsPayer', () => _platform.clearUserAsPayer());
  }

  @override
  void addUserPersona(String persona) {
    _runCatching('addUserPersona', () => _platform.addUserPersona(persona));
  }

  @override
  void clearUserPersona(String persona) {
    _runCatching('clearUserPersona', () => _platform.clearUserPersona(persona));
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
        // Explicit parent takes precedence over the Context current span.
        final effectiveParentSpanId =
            parent?.id ?? OTelContextUtils.currentSpan()?.embraceSpan.id;
        final id = await _platform.startSpan(
          name,
          parentSpanId: effectiveParentSpanId,
          startTimeMs: startTimeMs,
        );
        if (id != null) {
          final startDateTime = startTimeMs != null
              ? DateTime.fromMillisecondsSinceEpoch(startTimeMs)
              : DateTime.now();
          final impl = EmbraceSpanImpl(
            id,
            _platform,
            spanName: name,
            startTime: startDateTime,
            processor: _spanProcessor,
          );
          // Create an OTelSpanAdapter and register it as the current span in
          // OTel Context. The previous span (if any) is stored so that
          // stop() can restore it.
          final adapter = await OTelSpanAdapter.create(
            name,
            _SpanImplDelegate(impl),
          );
          final previous = OTelContextUtils.setCurrent(adapter);
          impl.attachOTelContext(adapter, previous);
          return impl;
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
        final convertedEvents = _convertSpanEvents(events);
        final result = await _platform.recordCompletedSpan(
          name,
          startTimeMs,
          endTimeMs,
          errorCode: errorCode,
          parentSpanId: parent?.id,
          attributes: attributes,
          events: convertedEvents,
        );
        final processor = _spanProcessor;
        if (processor != null) {
          // The native SDK owns span and trace IDs for recordCompletedSpan.
          // There is no API to retrieve them, so the OTel-invalid all-zeros
          // sentinels are used. Exported spans will not be correlatable with
          // native telemetry for this code path.
          unawaited(
            processor.onEnd(
              ReadableSpanData.fromRaw(
                name: name,
                spanId: _invalidSpanId,
                traceId: _invalidTraceId,
                startTimeMs: startTimeMs,
                endTimeMs: endTimeMs,
                errorCode: errorCode,
                attributes: attributes,
                events: convertedEvents,
                resource: processor.resource,
              ),
            ),
          );
        }
        return result;
      },
      defaultValue: false,
    );
  }

  @override
  Future<T> recordSpan<T>(
    String name, {
    EmbraceSpan? parent,
    Map<String, String>? attributes,
    List<EmbraceSpanEvent>? events,
    required Future<T> Function() code,
  }) async {
    return _runCatchingAndReturn<T>(
      'recordSpan',
      () async {
        final startTime = DateTime.now();
        final convertedEvents = _convertSpanEvents(events);
        final result = await _platform.recordSpan(
          name,
          code: code,
          parentSpanId: parent?.id,
          attributes: attributes,
          events: convertedEvents,
        );
        // endTime is captured after the platform call returns. This includes
        // method-channel round-trip overhead in addition to the user's callback
        // duration, which is an accepted limitation for this code path.
        //
        // The native SDK owns span and trace IDs for recordSpan; the
        // OTel-invalid all-zeros sentinels are used since there is no API to
        // retrieve them. Exported spans will not be correlatable with native
        // telemetry for this code path.
        final processor = _spanProcessor;
        if (processor != null) {
          unawaited(
            processor.onEnd(
              ReadableSpanData.fromRaw(
                name: name,
                spanId: _invalidSpanId,
                traceId: _invalidTraceId,
                startTimeMs: startTime.millisecondsSinceEpoch,
                endTimeMs: DateTime.now().millisecondsSinceEpoch,
                attributes: attributes,
                events: convertedEvents,
                resource: processor.resource,
              ),
            ),
          );
        }
        return result;
      },
      defaultValue: _defaultFor<T>(),
    );
  }
}

T _defaultFor<T>() {
  if (T == bool) return false as T;
  if (T == int) return 0 as T;
  if (T == double) return 0.0 as T;
  if (T == String) return '' as T;
  return (null as dynamic) as T;
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

Future<void> _installErrorHandlers(FutureOr<void> Function() action) async {
  _installFlutterOnError();
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

/// OTel-invalid all-zeros span ID (16 hex chars).
const _invalidSpanId = '0000000000000000';

/// OTel-invalid all-zeros trace ID (32 hex chars).
const _invalidTraceId = '00000000000000000000000000000000';

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
  EmbraceSpanImpl(
    super.id,
    this._platform, {
    String spanName = '',
    DateTime? startTime,
    EmbraceSpanProcessor? processor,
  })  : _name = spanName,
        _startTime = startTime ?? DateTime.now(),
        _processor = processor;

  final EmbracePlatform _platform;
  final String _name;

  final DateTime _startTime;
  final EmbraceSpanProcessor? _processor;
  OTelSpanAdapter? _otelAdapter;
  OTelSpanAdapter? _previousOtelAdapter;

  /// Attaches OTel context tracking to this span.
  ///
  /// [adapter] is the [OTelSpanAdapter] created for this span.
  /// [previous] is the span that was current before this one started — it
  /// will be restored to the OTel context when [stop] is called.
  void attachOTelContext(OTelSpanAdapter adapter, OTelSpanAdapter? previous) {
    _otelAdapter = adapter;
    _previousOtelAdapter = previous;
  }

  @override
  Future<String> get traceId async =>
      await _platform.getTraceId(id) ?? '0' * 32;

  @override
  Future<bool> stop({ErrorCode? errorCode, int? endTimeMs}) async {
    final result = await _platform.stopSpan(
      id,
      errorCode: errorCode,
      endTimeMs: endTimeMs,
    );
    if (_otelAdapter != null) {
      OTelContextUtils.restore(_previousOtelAdapter);
      _otelAdapter = null;
    }
    final processor = _processor;
    if (processor != null) {
      unawaited(_notifyProcessorOnEnd(processor, errorCode, endTimeMs));
    }
    return result;
  }

  Future<void> _notifyProcessorOnEnd(
    EmbraceSpanProcessor processor,
    ErrorCode? errorCode,
    int? endTimeMs,
  ) async {
    final rawTraceId = await traceId;
    await processor.onEnd(
      ReadableSpanData.fromRaw(
        name: _name,
        spanId: id,
        traceId: rawTraceId,
        startTimeMs: _startTime.millisecondsSinceEpoch,
        endTimeMs: endTimeMs ?? DateTime.now().millisecondsSinceEpoch,
        errorCode: errorCode,
        resource: processor.resource,
      ),
    );
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

/// Adapts an [EmbraceSpanImpl] to [EmbraceSpanDelegate] via composition so
/// that [OTelSpanAdapter] can wrap it without requiring inheritance.
class _SpanImplDelegate implements EmbraceSpanDelegate {
  const _SpanImplDelegate(this._impl);

  final EmbraceSpanImpl _impl;

  @override
  String get id => _impl.id;

  @override
  Future<String> get traceId => _impl.traceId;

  @override
  Future<bool> stop({ErrorCode? errorCode, int? endTimeMs}) =>
      _impl.stop(errorCode: errorCode, endTimeMs: endTimeMs);

  @override
  Future<bool> addEvent(
    String name, {
    int? timestampMs,
    Map<String, String>? attributes,
  }) =>
      _impl.addEvent(name, timestampMs: timestampMs, attributes: attributes);

  @override
  Future<bool> addAttribute(String key, String value) =>
      _impl.addAttribute(key, value);
}

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver(this._onDetached);

  final void Function() _onDetached;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _onDetached();
    }
  }
}
