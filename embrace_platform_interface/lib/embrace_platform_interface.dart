import 'dart:async';

import 'package:embrace_platform_interface/http_method.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:embrace_platform_interface/method_channel_embrace.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

///
///Categorize the broad reason a Span completed unsuccessfully.
///
enum ErrorCode {
  ///
  /// An application failure caused the Span to terminate
  ///
  failure,

  ///
  /// The operation tracked by the Span was terminated because the user
  /// abandoned and canceled it before it can complete successfully.
  ///
  abandon,

  ///
  /// The reason for the unsuccessful termination is unknown
  ///
  unknown
}

/// The interface that implementations of embrace must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `EmbracePlatform`.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
///  this interface will be broken by newly added [EmbracePlatform] methods.
abstract class EmbracePlatform extends PlatformInterface {
  /// Constructs a EmbracePlatform.
  EmbracePlatform() : super(token: _token);

  static final Object _token = Object();

  static EmbracePlatform _instance = MethodChannelEmbrace();

  /// The default instance of [EmbracePlatform] to use.
  ///
  /// Defaults to [MethodChannelEmbrace].
  static EmbracePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EmbracePlatform] when
  /// they register themselves.
  static set instance(EmbracePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Whether the SDK has been started.
  bool get isStarted =>
      throw UnimplementedError('isStarted has not been implemented.');

  /// Starts the Embrace SDK.
  Future<bool> attachToHostSdk({required bool enableIntegrationTesting}) {
    throw UnimplementedError('attachToHostSdk() has not been implemented.');
  }

  /// Logs a breadcrumb.
  void logBreadcrumb(String message) {
    throw UnimplementedError('logBreadcrumb(String) has not been implemented');
  }

  /// Adds a breadcrumb.
  void addBreadcrumb(String message) {
    throw UnimplementedError('addBreadcrumb(String) has not been implemented');
  }

  /// Logs a breadcrumb that indicates that the app received a push notification
  void logPushNotification({
    required String? title,
    required String? body,
    required String? subtitle,
    required int? badge,
    required String? category,
    required String? from,
    required String? messageId,
    required int? priority,
    required bool hasNotification,
    required bool hasData,
  }) {
    throw UnimplementedError('logInternalError() has not been implemented');
  }

  /// Log [message] and optional [properties] using the info log level.
  void logInfo(String message, Map<String, String>? properties) {
    throw UnimplementedError(
      'logInfo(String, Map<String, String> has not been implemented',
    );
  }

  /// Log [message] and optional [properties] using the warning log level.
  void logWarning(
    String message,
    Map<String, String>? properties,
  ) {
    throw UnimplementedError(
      'logWarning(String, Map<String, String>, bool) has not been implemented',
    );
  }

  /// Log [message] and optional [properties] using the error log level.
  void logError(
    String message,
    Map<String, String>? properties,
  ) {
    throw UnimplementedError(
      'logError(String, Map<string, String>, bool) has not been implemented',
    );
  }

  /// Log a network request.
  ///
  /// Use the [error] parameter to pass the reason phrase or exception message
  /// for requests that are not successful.
  void logNetworkRequest({
    required String url,
    required HttpMethod method,
    required int startTime,
    required int endTime,
    required int bytesSent,
    required int bytesReceived,
    required int statusCode,
    String? error,
    String? traceId,
    String? w3cTraceparent,
  }) {
    throw UnimplementedError('logNetworkRequest has not been implemented');
  }

  /// Generates a W3C Traceparent.
  Future<String?> generateW3cTraceparent(
    String? traceId,
    String? spanId,
  ) {
    throw UnimplementedError(
      'generateW3cTraceparent() has not been implemented',
    );
  }

  /// Signifies that a view has been mounted.
  void startView(String name) {
    throw UnimplementedError('startView(String) has not been implemented');
  }

  /// Signifies that a view has been unmounted.
  void endView(String name) {
    throw UnimplementedError('endView(String) has not been implemented');
  }

  /// Query the current device identifier.
  Future<String?> getDeviceId() {
    throw UnimplementedError('getDeviceId() has not been implemented');
  }

  /// Trigger a native SDK error.
  void triggerNativeSdkError() {
    throw UnimplementedError(
      'triggerNativeSdkError() has not been implemented',
    );
  }

  /// Triggers an ANR (Application Not Responding).
  void triggerAnr() {
    throw UnimplementedError('triggerAnr() has not been implemented');
  }

  /// Triggers a raised signal.
  void triggerRaisedSignal() {
    throw UnimplementedError('triggerRaisedSignal() has not been implemented');
  }

  /// Triggers a `MethodChannel` error.
  void triggerMethodChannelError() {
    throw UnimplementedError(
      'triggerMethodChannelError() has not been implemented',
    );
  }

  /// Sets the current user identifier to the provided [id].
  void setUserIdentifier(String id) {
    throw UnimplementedError(
      'setUserIdentifier(String) has not been implemented',
    );
  }

  /// Clears the current user identifier.
  void clearUserIdentifier() {
    throw UnimplementedError('clearUserIdentifier() has not been implemented');
  }

  /// Sets the current user name to the provided [name].
  void setUserName(String name) {
    throw UnimplementedError('setUserName(String) has not been implemented');
  }

  /// Clears the current user name.
  void clearUserName() {
    throw UnimplementedError('clearUserName() has not been implemented');
  }

  /// Sets the current user email to the provided [email].
  void setUserEmail(String email) {
    throw UnimplementedError('setUserEmail(String) has not been implemented');
  }

  /// Clears the current user email.
  void clearUserEmail() {
    throw UnimplementedError('clearUserEmail has not been implemented');
  }

  /// Sets the current user as a payer.
  void setUserAsPayer() {
    throw UnimplementedError('setUserAsPayer() has not been implemented');
  }

  /// Clears the current user's payer status.
  void clearUserAsPayer() {
    throw UnimplementedError('clearUserAsPayer() has not been implemented');
  }

  /// Adds the current user persona to the provided [persona].
  void addUserPersona(String persona) {
    throw UnimplementedError('addUserPersona(String) has not been implemented');
  }

  /// Clears the current user [persona].
  void clearUserPersona(String persona) {
    throw UnimplementedError(
      'clearUserPersona(String) has not been implemented',
    );
  }

  /// Clears the current users personas.
  void clearAllUserPersonas() {
    throw UnimplementedError('clearAllUserPersonas() has not been implemented');
  }

  /// Annotates the session with a property defined by a [key] and [value].
  ///
  /// The [key] must be unique within session properties. There is a limit of 10
  /// properties per session. If the property is [permanent], it will be added
  /// to all future sessions on this device. Otherwise, the property will just
  /// be added to the current session.
  void addSessionProperty(String key, String value, {required bool permanent}) {
    throw UnimplementedError('addSessionProperty() has not been implemented');
  }

  /// Remove an existing property from the session
  ///
  /// If the property was permament, it will be removed from all future
  /// sessions.
  void removeSessionProperty(String key) {
    throw UnimplementedError(
      'removeSessionProperty() has not been implemented',
    );
  }

  /// Manually forces the end of the current session and starts a new session.
  ///
  /// Only call this method if you have an application that will stay in the
  /// foreground for an extended time, such as a point-of-sale app.
  ///
  /// If [clearUserInfo] is true, it clears any username, user ID, and email
  /// values set when ending the session.
  void endSession({bool clearUserInfo = true}) {
    throw UnimplementedError('endSession() has not been implemented');
  }

  /// Logs an internal error within the SDK.
  void logInternalError(String message, String details) {
    throw UnimplementedError('logInternalError() has not been implemented');
  }

  /// Sends information from a Dart error/exception to the host SDK
  /// so that a log can be delivered.
  void logDartError(
    String? stack,
    String? message,
    String? context,
    String? library, {
    String? errorType,
    bool wasHandled = false,
  }) {
    throw UnimplementedError('logDartError() has not been implemented');
  }

  /// Create and start a new span. Returns the spanId of the new span
  /// if both operations are successful, and null if either fails.
  Future<String?> startSpan(
    String name, {
    String? parentSpanId,
    int? startTimeMs,
  }) {
    throw UnimplementedError('startSpan() has not been implemented');
  }

  /// Stop an active span. Returns true if the span is stopped after the
  /// method returns and false otherwise.
  Future<bool> stopSpan(String spanId, {ErrorCode? errorCode, int? endTimeMs}) {
    throw UnimplementedError('stopSpan() has not been implemented');
  }

  /// Create and add a Span Event with the given parameters to an active
  /// span with the given [spanId]. Returns false if the event
  /// cannot be added.
  Future<bool> addSpanEvent(
    String spanId,
    String name, {
    int? timestampMs,
    Map<String, String>? attributes,
  }) {
    throw UnimplementedError('addSpanEvent() has not been implemented');
  }

  /// Add an attribute to an active span with the given [spanId].
  /// Returns true if the attribute is added and false otherwise.
  Future<bool> addSpanAttribute(String spanId, String key, String value) {
    throw UnimplementedError('addSpanAttribute() has not been implemented');
  }

  /// Record a completed span with the given parameters.
  /// Returns true if the span is recorded and false otherwise.
  Future<bool> recordCompletedSpan(
    String name,
    int startTimeMs,
    int endTimeMs, {
    ErrorCode? errorCode,
    String? parentSpanId,
    Map<String, String>? attributes,
    List<Map<String, dynamic>>? events,
  }) {
    throw UnimplementedError('recordCompletedSpan() has not been implemented');
  }

  /// allows you to pass a lambda in so the runtime of that starts and ends a span
  Future<bool> recordSpan<T>(
    String name,
    {
    String? parentSpanId,
    Map<String, String>? attributes,
    List<Map<String, dynamic>>? events,
    required Future<T> Function() code,
  }) {
    throw UnimplementedError('recordSpan() has not been implemented');
  }

  /// Returns the end state of the previous run of the application.
  Future<LastRunEndState> getLastRunEndState() {
    throw UnimplementedError('getLastRunEndState() has not been implemented');
  }

  /// Returns the id of the current session.
  Future<String?> getCurrentSessionId() {
    throw UnimplementedError('getCurrentSessionId() has not been implemented');
  }

  /// Gets the trace ID for a given span ID.
  Future<String?> getTraceId(
    String spanId,
  ) {
    throw UnimplementedError(
      'getTraceId() has not been implemented',
    );
  }
}
