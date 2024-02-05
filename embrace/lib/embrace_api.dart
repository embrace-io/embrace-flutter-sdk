import 'dart:async';

import 'package:embrace_platform_interface/http_method.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';

/// Declares the functions that consist of Embrace's public API - specifically
/// those that are only declared on Flutter. You should not use
/// EmbraceFlutterApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.

abstract class EmbraceFlutterApi implements EmbraceApi {
  /// Starts instrumentation of Dart code by the Embrace SDK. This should be
  /// wrap the entire contents of your Dart main() function if you
  /// wish to capture Dart errors.
  ///
  /// You must also call Embrace.instance.start as soon as possible in your
  /// Android and iOS native code.
  Future<void> start(
    FutureOr<void> Function() action, {
    bool enableIntegrationTesting = false,
  });

  /// Manually logs a Dart error or exception to Embrace. You should use this
  /// if you want to capture errors/exceptions and report them to Embrace.
  /// A good example would be to call this function from within a try-catch
  /// block.
  ///
  /// It is not necessary to call this function for uncaught Flutter errors
  /// or Dart errors originating from the root isolate - Embrace automatically
  /// captures these errors already.
  void logDartError(Object error, StackTrace stack);

  /// Manually logs a handled Dart error or exception to Embrace. This is
  /// equivalent to [logDartError] but records the error as handled. Handled
  /// errors do not count towards calculation of error-free sessions.
  void logHandledDartError(Object error, StackTrace stack);

  /// Get the exit status (crash or clean exit) of the last time the
  /// application was run.
  Future<LastRunEndState> getLastRunEndState();
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use EmbraceApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class EmbraceApi
    implements LogsApi, MomentsApi, NetworkRequestApi, SessionApi, UserApi {
  /// Logs a breadcrumb.
  ///
  /// Breadcrumbs track a user's journey through the application and will be
  /// shown on the timeline.
  @Deprecated(
      'Use addBreadcrumb() instead. This API will be removed in a future '
      'major version release.')
  void logBreadcrumb(String message);

  /// Adds a breadcrumb.
  ///
  /// Breadcrumbs track a user's journey through the application and will be
  /// shown on the timeline.
  void addBreadcrumb(String message);

  /// Manually logs a push notification as a breadcrumb
  ///
  /// The parameters [subtitle], [badge] and [category] are exclusive to iOS
  /// notifications, while the parameters [from], [messageId], [priority],
  /// [hasNotification] and [hasData] are exclusive to Android notifications
  void logPushNotification(
    String? title,
    String? body, {
    String? subtitle,
    int? badge,
    String? category,
    String? from,
    String? messageId,
    int priority = 0,
    bool hasNotification = false,
    bool hasData = false,
  });

  /// Log the start of a view.
  ///
  /// A matching call to [endView] must be made.
  void startView(String name);

  /// Log the end of a view.
  ///
  /// A matching call to [startView] must be made before ending the view.
  void endView(String name);

  /// Get the Embrace user identifier assigned to the device.
  Future<String?> getDeviceId();
}

/// The severity of the log message
enum Severity {
  /// An info-level log message.
  info,

  /// A warning-level log message.
  warning,

  /// An error-level log message.
  error
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use LogsApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class LogsApi {
  /// Remotely logs a message at INFO level
  void logInfo(String message, {Map<String, String>? properties});

  /// Remotely logs a message at WARNING level
  void logWarning(
    String message, {
    Map<String, String>? properties,
    bool allowScreenshot = false,
  });

  /// Remotely logs a message at ERROR level
  void logError(
    String message, {
    Map<String, String>? properties,
    bool allowScreenshot = false,
  });

  /// Remotely logs a message at the given severity level
  void logMessage(
    String message,
    Severity severity, {
    Map<String, String>? properties,
  });
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use MomentsApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class MomentsApi {
  /// Starts a moment.
  ///
  /// Moments are used for encapsulating particular activities within the app,
  /// such as the user adding an item to their shopping cart. The length of time
  /// a moment takes to execute is recorded, and a screenshot can be taken if a
  /// moment is 'late'.
  void startMoment(
    String name, {
    String? identifier,
    bool allowScreenshot = false,
    Map<String, String>? properties,
  });

  /// Signals the end of a moment with the specified [name] and [identifier].
  ///
  /// The duration of the moment is computed, and a screenshot taken
  /// (if enabled) if the moment was late.
  void endMoment(
    String name, {
    String? identifier,
    Map<String, String>? properties,
  });

  /// Signals that the app has completed startup.
  @Deprecated(
      'Use endAppStartup() instead. This API will be removed in a future '
      'major version release.')
  void endStartupMoment({Map<String, String>? properties});

  /// Signals that the app has completed startup.
  void endAppStartup({Map<String, String>? properties});
}

/// This class is used to create manually-recorded network requests.
class EmbraceNetworkRequest {
  EmbraceNetworkRequest._({
    required this.url,
    required this.httpMethod,
    required this.startTime,
    required this.endTime,
    required this.bytesSent,
    required this.bytesReceived,
    required this.statusCode,
    required this.errorDetails,
    this.traceId,
  });

  /// Network request URL.
  final String url;

  /// Network request HTTP method.
  final HttpMethod httpMethod;

  /// Network request start time in ms.
  final int startTime;

  /// Network request end time in ms.
  final int endTime;

  /// Bytes sent as part of the network request.
  final int bytesSent;

  /// Bytes received as part of the network request.
  final int bytesReceived;

  /// HTTP status code
  final int statusCode;

  /// Error string if the request did not complete
  final String? errorDetails;

  /// Optional trace ID for distributed tracing
  final String? traceId;

  /// Construct a new [EmbraceNetworkRequest] instance where a HTTP response
  /// was not returned.
  /// If a response was returned, use [fromCompletedRequest] instead.
  ///
  /// - [url]: the URL of the request.
  /// - [httpMethod]: the HTTP method of the request.
  /// - [startTime]: the start time of the request.
  /// - [endTime]: the end time of the request.
  /// Returns a new [EmbraceNetworkRequest] instance.
  // ignore: prefer_constructors_over_static_methods
  static EmbraceNetworkRequest fromIncompleteRequest({
    required String url,
    required HttpMethod httpMethod,
    required int startTime,
    required int endTime,
    required String errorDetails,
    String? traceId,
  }) {
    return EmbraceNetworkRequest._(
      url: url,
      httpMethod: httpMethod,
      startTime: startTime,
      endTime: endTime,
      bytesSent: -1,
      bytesReceived: -1,
      statusCode: -1,
      traceId: traceId,
      errorDetails: errorDetails,
    );
  }

  /// Construct a new [EmbraceNetworkRequest] instance where a HTTP response
  /// was returned.
  /// If no response was returned, use [fromIncompleteRequest] instead.
  ///
  /// - [url]: the URL of the request.
  /// - [httpMethod]: the HTTP method of the request.
  /// - [startTime]: the start time of the request.
  /// - [endTime]: the end time of the request.
  /// - [bytesSent]: the number of bytes sent.
  /// - [bytesReceived]: the number of bytes received.
  /// - [statusCode]: the status code of the response.
  /// - [traceId]: the trace ID of the request, used for distributed tracing.
  /// Returns a new [EmbraceNetworkRequest] instance.
  // ignore: prefer_constructors_over_static_methods
  static EmbraceNetworkRequest fromCompletedRequest({
    required String url,
    required HttpMethod httpMethod,
    required int startTime,
    required int endTime,
    required int bytesSent,
    required int bytesReceived,
    required int statusCode,
    String? traceId,
  }) {
    return EmbraceNetworkRequest._(
      url: url,
      httpMethod: httpMethod,
      startTime: startTime,
      endTime: endTime,
      bytesSent: bytesSent,
      bytesReceived: bytesReceived,
      statusCode: statusCode,
      errorDetails: null,
      traceId: traceId,
    );
  }
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use NetworkRequestApi directly or implement it in your own custom
/// classes, as new functions may be added in future. Use the Embrace class
/// instead.
// ignore: one_member_abstracts
abstract class NetworkRequestApi {
  /// Log a network request.
  ///
  /// Use the [error] parameter to pass the reason phrase or exception message
  /// for requests that are not successful.
  ///
  /// [startTime] and [endTime] should be Unix timestamps, or the
  /// number of milliseconds since 1970-01-01T00:00:00Z (UTC),
  /// e.g. `DateTime.now.millisecondsSinceEpoch`.
  @Deprecated(
    'Use recordNetworkRequest() instead. This API will be removed '
    'in a future major version release.',
  )
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
  });

  /// Records a network request to Embrace.
  void recordNetworkRequest(EmbraceNetworkRequest request);
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use SessionApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class SessionApi {
  /// Annotates the session with a property defined by a [key] and [value].
  ///
  /// The [key] must be unique within session properties. There is a limit of 10
  /// properties per session. If the property is [permanent], it will be added
  /// to all future sessions on this device. Otherwise, the property will just
  /// be added to the current session.
  void addSessionProperty(String key, String value, {bool permanent = false});

  /// Remove an existing property from the session
  ///
  /// If the property was permanent, it will be removed from all future
  /// sessions.
  void removeSessionProperty(String key);

  /// Returns all properties for the current session.
  ///
  /// Modifications to the returned map will not be applied to the session. To
  /// modify the session properties, use [addSessionProperty] and
  /// [removeSessionProperty].
  Future<Map<String, String>> getSessionProperties();

  /// Manually forces the end of the current session and starts a new session.
  ///
  /// Only call this method if you have an application that will stay in the
  /// foreground for an extended time, such as a point-of-sale app.
  ///
  /// If [clearUserInfo] is true, it clears any username, user ID, and email
  /// values set when ending the session.
  void endSession({bool clearUserInfo = true});

  /// Get the ID for the current session.
  ///
  /// Returns null if a session has not been started yet or the SDK hasn't been
  /// initialized.
  Future<String?> getCurrentSessionId();
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use UserApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class UserApi {
  /// Sets the user identifier
  ///
  /// This would typically be some form of unique identifier such as a UUID or
  /// database key for the user.
  /// Embrace will generate a per-install UUID by default.
  void setUserIdentifier(String id);

  /// Clears the currently set user identifier.
  void clearUserIdentifier();

  /// Sets the current user's name.
  void setUserName(String name);

  /// Clear the currently set user name.
  void clearUserName();

  /// Sets the current user's email.
  void setUserEmail(String email);

  /// Clear the currently set user email.
  void clearUserEmail();

  /// Sets this user as a paying user.
  ///
  /// This adds a persona to the user's identity.
  void setUserAsPayer();

  /// Clears this user as a paying user.
  ///
  /// This would typically be called if a user is no longer paying for
  /// the service and has reverted back to a basic user.
  void clearUserAsPayer();

  /// Sets a custom user persona.
  ///
  /// A persona is a trait associated with a given user.
  @Deprecated(
      'Use addUserPersona() instead. This API will be removed in a future '
      'major version release.')
  void setUserPersona(String persona);

  /// Adds a custom user persona.
  ///
  /// A persona is a trait associated with a given user.
  void addUserPersona(String persona);

  /// Clears the custom user persona, if it is set.
  void clearUserPersona(String persona);

  /// Clears all custom user personas from the user.
  void clearAllUserPersonas();
}
