import 'dart:async';

import 'package:embrace_platform_interface/http_method.dart';
import 'package:embrace_platform_interface/method_channel_embrace.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  /// Map representing the remote config provided by the platform SDK.
  ///
  /// The remote config is fetched asynchronously when the Embrace SDK is
  /// started and may be updated at runtime. Use the [remoteConfigUpdates]
  /// stream to listen for updates.
  Map<String, dynamic> get remoteConfig => _remoteConfig;
  Map<String, dynamic> _remoteConfig = {};

  /// A stream of updates to the remote config provided by the platform SDK.
  Stream<Map<String, dynamic>> get remoteConfigUpdates =>
      _remoteConfigUpdates.stream;
  final _remoteConfigUpdates =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);

  /// Sets the value of [remoteConfig].
  ///
  /// Calling this function will emit a synchronous event in the
  /// [remoteConfigUpdates] stream.
  void setRemoteConfig(Map<String, dynamic> newConfig) {
    _remoteConfig = newConfig;
    _remoteConfigUpdates.add(_remoteConfig);
  }

  /// Whether the SDK has been started.
  bool get isStarted =>
      throw UnimplementedError('isStarted has not been implemented.');

  /// Starts the Embrace SDK.
  Future<bool> attachToHostSdk({required bool enableIntegrationTesting}) {
    throw UnimplementedError('attachToHostSdk() has not been implemented.');
  }

  /// Signifies that application startup has ended.
  void endAppStartup(Map<String, String>? properties) {
    throw UnimplementedError('endAppStartup() has not been implemented.');
  }

  /// Logs a breadcrumb.
  void logBreadcrumb(String message) {
    throw UnimplementedError('logBreadcrumb(String) has not been implemented');
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
    Map<String, String>? properties, {
    required bool allowScreenshot,
  }) {
    throw UnimplementedError(
      'logWarning(String, Map<String, String>, bool) has not been implemented',
    );
  }

  /// Log [message] and optional [properties] using the error log level.
  void logError(
    String message,
    Map<String, String>? properties, {
    required bool allowScreenshot,
  }) {
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
  }) {
    throw UnimplementedError('logNetworkRequest has not been implemented');
  }

  /// Signifies that a view has been mounted.
  void startView(String name) {
    throw UnimplementedError('startView(String) has not been implemented');
  }

  /// Signifies that a view has been unmounted.
  void endView(String name) {
    throw UnimplementedError('endView(String) has not been implemented');
  }

  /// Start a moment with the provided [name] and optional [identifier].
  void startMoment(
    String name,
    String? identifier,
    Map<String, String>? properties, {
    required bool allowScreenshot,
  }) {
    throw UnimplementedError('startMoment(String) has not been implemented');
  }

  /// End a moment with the provided [name] and optional [identifier].
  void endMoment(
    String name,
    String? identifier,
    Map<String, String>? properties,
  ) {
    throw UnimplementedError('endMoment(String) has not been implemented');
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

  /// Sets the current user persona to the provided [persona].
  void setUserPersona(String persona) {
    throw UnimplementedError('setUserPersona(String) has not been implemented');
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

  /// Returns all properties for the current session.
  ///
  /// Modifications to the returned map will not be applied to the session. To
  /// modify the session properties, use [addSessionProperty] and
  /// [removeSessionProperty].
  Future<Map<String, String>> getSessionProperties() {
    throw UnimplementedError('getSessionProperties() has not been implemented');
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
  }) {
    throw UnimplementedError('logDartError() has not been implemented');
  }
}
