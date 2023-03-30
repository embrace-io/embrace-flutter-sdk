import 'dart:async';

import 'package:embrace_platform_interface/http_method.dart';

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
}

/// Declares the functions that consist of Embrace's public API. You should
/// not use EmbraceApi directly or implement it in your own custom classes,
/// as new functions may be added in future. Use the Embrace class instead.
abstract class EmbraceApi {
  /// Signals that the app has completed startup.
  void endStartupMoment({Map<String, String>? properties});

  /// Logs a breadcrumb.
  ///
  /// Breadcrumbs track a user's journey through the application and will be
  /// shown on the timeline.
  void logBreadcrumb(String message);

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

  /// Log a network request.
  ///
  /// Use the [error] parameter to pass the reason phrase or exception message
  /// for requests that are not successful.
  ///
  /// [startTime] and [endTime] should be Unix timestamps, or the
  /// number of milliseconds since 1970-01-01T00:00:00Z (UTC),
  /// e.g. `DateTime.now.millisecondsSinceEpoch`.
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

  /// Log the start of a view.
  ///
  /// A matching call to [endView] must be made.
  void startView(String name);

  /// Log the end of a view.
  ///
  /// A matching call to [startView] must be made before ending the view.
  void endView(String name);

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
  void setUserPersona(String persona);

  /// Clears the custom user persona, if it is set.
  void clearUserPersona(String persona);

  /// Clears all custom user personas from the user.
  void clearAllUserPersonas();

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

  /// Get the Embrace user identifier assigned to the device.
  Future<String?> getDeviceId();
}
