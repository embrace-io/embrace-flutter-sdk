import 'dart:async';

import 'package:embrace_platform_interface/embrace_platform_interface.dart';
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
    implements LogsApi, NetworkRequestApi, SessionApi, TracingApi, UserApi {
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
  error,
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use LogsApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class LogsApi {
  /// Remotely logs a message at INFO level
  void logInfo(String message, {Map<String, String>? properties});

  /// Remotely logs a message at WARNING level
  void logWarning(String message, {Map<String, String>? properties});

  /// Remotely logs a message at ERROR level
  void logError(String message, {Map<String, String>? properties});

  /// Remotely logs a message at the given severity level
  void logMessage(
    String message,
    Severity severity, {
    Map<String, String>? properties,
  });
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
    this.w3cTraceparent,
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

  /// Optional w3c trace parent for network span forwarding
  final String? w3cTraceparent;

  /// Construct a new [EmbraceNetworkRequest] instance where a HTTP response
  /// was not returned.
  /// If a response was returned, use [fromCompletedRequest] instead.
  ///
  /// - [url]: the URL of the request.
  /// - [httpMethod]: the HTTP method of the request.
  /// - [startTime]: the start time of the request.
  /// - [endTime]: the end time of the request.
  /// - [errorDetails]: string describing the error details
  /// - [traceId]: the trace ID of the request, used for distributed tracing.
  /// - [w3cTraceparent]: a w3c trace parent of the request, used to
  /// enable network span forwarding
  /// Returns a new [EmbraceNetworkRequest] instance.
  // ignore: prefer_constructors_over_static_methods
  static EmbraceNetworkRequest fromIncompleteRequest({
    required String url,
    required HttpMethod httpMethod,
    required int startTime,
    required int endTime,
    required String errorDetails,
    String? traceId,
    String? w3cTraceparent,
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
      w3cTraceparent: w3cTraceparent,
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
  /// - [w3cTraceparent]: a w3c trace parent of the request, used to
  /// enable network span forwarding
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
    String? w3cTraceparent,
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
      w3cTraceparent: w3cTraceparent,
    );
  }
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use NetworkRequestApi directly or implement it in your own custom
/// classes, as new functions may be added in future. Use the Embrace class
/// instead.
// ignore: one_member_abstracts
abstract class NetworkRequestApi {
  /// Records a network request to Embrace.
  void recordNetworkRequest(EmbraceNetworkRequest request);

  /// Generates a W3C traceparent header for network span forwarding, or null
  /// if this has not been enabled.
  /// For iOS, it's required to pass in the spanId and traceId of the network
  /// span that is being forwarded. For Android, these parameters are ignored.
  Future<String?> generateW3cTraceparent(String? traceId, String? spanId);
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

  /// Adds a custom user persona.
  ///
  /// A persona is a trait associated with a given user.
  void addUserPersona(String persona);

  /// Clears the custom user persona, if it is set.
  void clearUserPersona(String persona);

  /// Clears all custom user personas from the user.
  void clearAllUserPersonas();
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use TracingApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class TracingApi {
  ///
  /// Create and start a new span. Returns a reference to the new span on
  /// success and null on failure.
  ///
  Future<EmbraceSpan?> startSpan(
    String name, {
    EmbraceSpan? parent,
    int? startTimeMs,
  }) {
    throw UnimplementedError('Not implemented yet.');
  }

  /// Record a span with the given name, error code, parent, start time, and
  /// end time (epoch time in milliseconds). Passing in a parent
  /// that is null will result in a new trace with the new span as its root.
  /// A non-null [ErrorCode] can be passed in to denote the
  /// operation the span represents was ended unsuccessfully under the stated
  /// circumstances. You can also pass in a [Map]
  /// with [String] keys and values to be used as the attributes of the recorded
  /// span, or a [List] of [EmbraceSpanEvent] to be used
  /// as the events of the recorded span.
  ///
  Future<bool> recordCompletedSpan<T>(
    String name,
    int startTimeMs,
    int endTimeMs, {
    ErrorCode? errorCode,
    EmbraceSpan? parent,
    Map<String, String>? attributes,
    List<EmbraceSpanEvent>? events,
  }) {
    throw UnimplementedError('Not implemented yet.');
  }

  /// Wraps some code in a start and stop span so you can measure the time
  /// it takes for the code to run
  Future<T> recordSpan<T>(
    String name, {
    EmbraceSpan? parent,
    Map<String, String>? attributes,
    List<EmbraceSpanEvent>? events,
    required Future<T> Function() code,
  }) {
    throw UnimplementedError('Not implemented yet.');
  }
}

/// Represents a Span that can be started and stopped with the appropriate
/// [ErrorCode] if applicable. This wraps the OpenTelemetry Span
/// by adding an additional layer for local validation
///
abstract class EmbraceSpan {
  /// constructor
  EmbraceSpan(this.id);

  /// ID for this span
  final String id;

  /// ID for the trace this span belongs to
  abstract final Future<String?> traceId;

  ///
  /// Stop an active span. Returns true if the span is stopped after the method
  /// returns and false otherwise.
  ///
  Future<bool> stop({ErrorCode? errorCode, int? endTimeMs});

  ///
  /// Add an [EmbraceSpanEvent] with the given [name]. If [timestampMs] is null,
  /// the current time will be used. Optionally, the specific
  /// time of the event and a set of attributes can be passed in associated with
  /// the event. Returns false if the Event was definitely not
  /// successfully added. Returns true if the validation at the Embrace level
  /// has passed and the call to add the Event at the
  /// OpenTelemetry level was successful.
  ///
  Future<bool> addEvent(
    String name, {
    int? timestampMs,
    Map<String, String>? attributes,
  });

  ///
  /// Add the given key-value pair as an Attribute to the Event. Returns false
  /// if the Attribute was definitely not added. Returns true
  /// if the validation at the Embrace Level has passed and the call to add the
  /// Attribute at the OpenTelemetry level was successful.
  ///
  Future<bool> addAttribute(String key, String value);
}

///
/// Represents an Event in an [EmbraceSpan]
///
class EmbraceSpanEvent {
  /// Constructor
  EmbraceSpanEvent({
    required this.name,
    required this.timestampMs,
    required this.attributes,
  });

  /// The name of the event
  final String name;

  /// The timestamp of the event in milliseconds
  final int timestampMs;

  /// The attributes of this event
  final Map<String, String> attributes;

  /// Produces a map representation of this class
  Map<String, dynamic> toMap() {
    return {'name': name, 'timestampMs': timestampMs, 'attributes': attributes};
  }
}
