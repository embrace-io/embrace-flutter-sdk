import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/http_method.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:embrace_platform_interface/src/version.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:platform/platform.dart';

/// An implementation of [EmbracePlatform] that uses method channels.
class MethodChannelEmbrace extends EmbracePlatform {
  /// Constructs an instance of MethodChannelEmbrace
  MethodChannelEmbrace({Platform? platform})
      : _platform = platform ?? const LocalPlatform();

  static const String _methodChannelName = 'embrace';

  // Method Names
  static const String _attachSdkMethodName = 'attachToHostSdk';
  static const String _endStartupMomentMethodName = 'endStartupMoment';
  static const String _logBreadcrumbMethodName = 'logBreadcrumb';
  static const String _logPushNotificationMethodName = 'logPushNotification';
  static const String _startMomentMethodName = 'startMoment';
  static const String _endMomentMethodName = 'endMoment';
  static const String _startViewMethodName = 'startView';
  static const String _endViewMethodName = 'endView';
  static const String _getDeviceIdMethodName = 'getDeviceId';
  static const String _logInfoMethodName = 'logInfo';
  static const String _logWarningMethodName = 'logWarning';
  static const String _logErrorMethodName = 'logError';
  static const String _setUserIdentifierMethodName = 'setUserIdentifier';
  static const String _setUserNameMethodName = 'setUserName';
  static const String _setUserEmailMethodName = 'setUserEmail';
  static const String _setUserAsPayerMethodName = 'setUserAsPayer';
  static const String _setUserPersonaMethodName = 'setUserPersona';
  static const String _clearUserIdentifierMethodName = 'clearUserIdentifier';
  static const String _clearUserNameMethodName = 'clearUserName';
  static const String _clearUserEmailMethodName = 'clearUserEmail';
  static const String _clearUserAsPayerMethodName = 'clearUserAsPayer';
  static const String _clearUserPersonaMethodName = 'clearUserPersona';
  static const String _clearAllUserPersonasMethodName = 'clearAllUserPersonas';
  static const String _logNetworkRequestMethodName = 'logNetworkRequest';
  static const String _logInternalErrorMethodName = 'logInternalError';
  static const String _logDartErrorMethodName = 'logDartError';
  static const String _addSessionPropertyMethodName = 'addSessionProperty';
  static const String _removeSessionPropertyMethodName =
      'removeSessionProperty';
  static const String _getSessionPropertiesMethodName = 'getSessionProperties';
  static const String _endSessionMethodName = 'endSession';
  static const String _getLastRunEndStateMethodName = 'getLastRunEndState';

  // Parameter Names
  static const String _propertiesArgName = 'properties';
  static const String _messageArgName = 'message';
  static const String _nameArgName = 'name';
  static const String _identifierArgName = 'identifier';
  static const String _allowScreenshotArgName = 'allowScreenshot';
  static const String _userIdArgName = 'identifier';
  static const String _userNameArgName = 'name';
  static const String _userEmailArgName = 'email';
  static const String _userPersonaArgName = 'persona';
  static const String _enableIntegrationTestingArgName =
      'enableIntegrationTesting';
  static const String _urlArgName = 'url';
  static const String _httpMethodArgName = 'httpMethod';
  static const String _startTimeArgName = 'startTime';
  static const String _endTimeArgName = 'endTime';
  static const String _bytesSentArgName = 'bytesSent';
  static const String _bytesReceivedArgName = 'bytesReceived';
  static const String _statusCodeArgName = 'statusCode';
  static const String _errorArgName = 'error';
  static const String _traceIdArgName = 'traceId';
  static const String _detailsArgName = 'details';
  static const String _embraceFlutterSdkVersionArgName =
      'embraceFlutterSdkVersion';
  static const String _dartRuntimeVersionArgName = 'dartRuntimeVersion';
  static const String _errorStackArgName = 'stack';
  static const String _errorMessageArgName = 'message';
  static const String _errorContextArgName = 'context';
  static const String _errorLibraryArgName = 'library';
  static const String _errorTypeArgName = 'type';
  static const String _keyArgName = 'key';
  static const String _valueArgName = 'value';
  static const String _permanentArgName = 'permanent';
  static const String _clearUserInfoArgName = 'clearUserInfo';
  static const String _titleArgName = 'title';
  static const String _bodyArgName = 'body';
  static const String _subtitleArgName = 'subtitle';
  static const String _badgeArgName = 'badge';
  static const String _categoryArgName = 'category';
  static const String _fromArgName = 'from';
  static const String _messageIdArgName = 'messageId';
  static const String _priorityArgName = 'priority';
  static const String _hasNotificationArgName = 'hasNotification';
  static const String _hasDataArgName = 'hasData';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(_methodChannelName);

  final Platform _platform;

  bool _isStarted = false;

  @override
  bool get isStarted => _isStarted;

  @override
  Future<bool> attachToHostSdk({required bool enableIntegrationTesting}) async {
    if (isStarted) {
      if (kDebugMode) {
        print('Embrace SDK has already started!');
      }
      return false;
    }

    _isStarted = true;

    debugPrint('Embrace Flutter SDK Version: $packageVersion');

    methodChannel.setMethodCallHandler(handleMethodCall);

    final success = await methodChannel.invokeMethod<bool?>(
          _attachSdkMethodName,
          {
            _enableIntegrationTestingArgName: enableIntegrationTesting,
            _embraceFlutterSdkVersionArgName: packageVersion,
            _dartRuntimeVersionArgName: _platform.version.replaceAll('"', ''),
          },
        ) ??
        false;
    if (!success) {
      if (kDebugMode) {
        print(
          'The Embrace SDK was not started in Android/iOS native code. '
          'This likely indicates a problem with your integration. We '
          'recommend reviewing your Application/AppDelegate classes to ensure '
          'Embrace.start is called for each native SDK. The Flutter SDK will '
          'attempt to initialize the native SDK regardless but your '
          'experience may be degraded by initializing late.',
        );
      }
    } else {
      if (kDebugMode) {
        print('Embrace Flutter SDK attached to host SDK successfully.');
      }
    }
    return success;
  }

  @override
  void endAppStartup(Map<String, String>? properties) {
    throwIfNotStarted();
    methodChannel.invokeMethod(
      _endStartupMomentMethodName,
      {_propertiesArgName: properties},
    );
  }

  @override
  void logBreadcrumb(String message) {
    throwIfNotStarted();
    methodChannel
        .invokeMethod(_logBreadcrumbMethodName, {_messageArgName: message});
  }

  @override
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
    throwIfNotStarted();
    methodChannel.invokeMethod(_logPushNotificationMethodName, {
      _titleArgName: title,
      _bodyArgName: body,
      _subtitleArgName: subtitle,
      _badgeArgName: badge,
      _categoryArgName: category,
      _fromArgName: from,
      _messageIdArgName: messageId,
      _priorityArgName: priority,
      _hasNotificationArgName: hasNotification,
      _hasDataArgName: hasData
    });
  }

  @override
  void logInfo(String message, Map<String, String>? properties) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_logInfoMethodName, {
      _messageArgName: message,
      _propertiesArgName: properties,
    });
  }

  @override
  void logWarning(
    String message,
    Map<String, String>? properties, {
    required bool allowScreenshot,
  }) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_logWarningMethodName, {
      _messageArgName: message,
      _propertiesArgName: properties,
      _allowScreenshotArgName: allowScreenshot,
    });
  }

  @override
  void logError(
    String message,
    Map<String, String>? properties, {
    required bool allowScreenshot,
  }) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_logErrorMethodName, {
      _messageArgName: message,
      _propertiesArgName: properties,
      _allowScreenshotArgName: allowScreenshot,
    });
  }

  @override
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
    throwIfNotStarted();

    methodChannel.invokeMethod(_logNetworkRequestMethodName, {
      _urlArgName: url,
      _httpMethodArgName: method.toHttpString().toLowerCase(),
      _startTimeArgName: startTime,
      _endTimeArgName: endTime,
      _bytesSentArgName: bytesSent,
      _bytesReceivedArgName: bytesReceived,
      _statusCodeArgName: statusCode,
      _errorArgName: error,
      _traceIdArgName: traceId,
    });
  }

  @override
  void startView(String name) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_startViewMethodName, {_nameArgName: name});
  }

  @override
  void endView(String name) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_endViewMethodName, {_nameArgName: name});
  }

  @override
  void startMoment(
    String name,
    String? identifier,
    Map<String, String>? properties, {
    required bool allowScreenshot,
  }) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_startMomentMethodName, {
      _nameArgName: name,
      _identifierArgName: identifier,
      _allowScreenshotArgName: allowScreenshot,
      _propertiesArgName: properties
    });
  }

  @override
  void endMoment(
    String name,
    String? identifier,
    Map<String, String>? properties,
  ) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_endMomentMethodName, {
      _nameArgName: name,
      _identifierArgName: identifier,
      _propertiesArgName: properties
    });
  }

  @override
  Future<String?> getDeviceId() async {
    final version =
        await methodChannel.invokeMethod<String>(_getDeviceIdMethodName);
    return version;
  }

  @override
  void triggerNativeSdkError() {
    throwIfNotStarted();
    methodChannel.invokeMethod('triggerNativeSdkError');
  }

  @override
  void triggerAnr() {
    throwIfNotStarted();
    methodChannel.invokeMethod('triggerAnr');
  }

  @override
  void triggerRaisedSignal() {
    throwIfNotStarted();
    methodChannel.invokeMethod('triggerRaisedSignal');
  }

  @override
  void triggerMethodChannelError() {
    throwIfNotStarted();
    methodChannel.invokeMethod('triggerMethodChannelError');
  }

  @override
  void setUserIdentifier(String id) {
    throwIfNotStarted();
    methodChannel
        .invokeMethod(_setUserIdentifierMethodName, {_userIdArgName: id});
  }

  @override
  void clearUserIdentifier() {
    throwIfNotStarted();
    methodChannel.invokeMethod(_clearUserIdentifierMethodName);
  }

  @override
  void setUserName(String name) {
    throwIfNotStarted();
    methodChannel
        .invokeMethod(_setUserNameMethodName, {_userNameArgName: name});
  }

  @override
  void clearUserName() {
    throwIfNotStarted();
    methodChannel.invokeMethod(_clearUserNameMethodName);
  }

  @override
  void setUserEmail(String email) {
    throwIfNotStarted();
    methodChannel
        .invokeMethod(_setUserEmailMethodName, {_userEmailArgName: email});
  }

  @override
  void clearUserEmail() {
    throwIfNotStarted();
    methodChannel.invokeMethod(_clearUserEmailMethodName);
  }

  @override
  void setUserAsPayer() {
    throwIfNotStarted();
    methodChannel.invokeMapMethod<dynamic, dynamic>(_setUserAsPayerMethodName);
  }

  @override
  void clearUserAsPayer() {
    throwIfNotStarted();
    methodChannel.invokeMethod(_clearUserAsPayerMethodName);
  }

  @override
  void setUserPersona(String persona) {
    throwIfNotStarted();
    methodChannel.invokeMethod(
      _setUserPersonaMethodName,
      {_userPersonaArgName: persona},
    );
  }

  @override
  void clearUserPersona(String persona) {
    throwIfNotStarted();
    methodChannel.invokeMethod(
      _clearUserPersonaMethodName,
      {_userPersonaArgName: persona},
    );
  }

  @override
  void clearAllUserPersonas() {
    throwIfNotStarted();
    methodChannel.invokeMethod(_clearAllUserPersonasMethodName);
  }

  @override
  void addSessionProperty(String key, String value, {required bool permanent}) {
    throwIfNotStarted();
    methodChannel.invokeMethod(
      _addSessionPropertyMethodName,
      {
        _keyArgName: key,
        _valueArgName: value,
        _permanentArgName: permanent,
      },
    );
  }

  @override
  void removeSessionProperty(String key) {
    throwIfNotStarted();
    methodChannel
        .invokeMethod(_removeSessionPropertyMethodName, {_keyArgName: key});
  }

  @override
  void endSession({bool clearUserInfo = true}) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_endSessionMethodName, {
      _clearUserInfoArgName: clearUserInfo,
    });
  }

  @override
  Future<Map<String, String>> getSessionProperties() async {
    throwIfNotStarted();
    final properties = await methodChannel
        .invokeMapMethod<String, String>(_getSessionPropertiesMethodName);
    return properties ?? const {};
  }

  @override
  void logInternalError(String message, String details) {
    throwIfNotStarted();
    methodChannel.invokeMethod(
      _logInternalErrorMethodName,
      {_messageArgName: message, _detailsArgName: details},
    );
  }

  @override
  void logDartError(
    String? stack,
    String? message,
    String? context,
    String? library, {
    String? errorType,
  }) {
    // return silently instead of throwing a StateError - as throwing an
    // exception during exception handling would likely cause an error loop.
    if (!isStarted) {
      return;
    }

    try {
      methodChannel.invokeMethod(
        _logDartErrorMethodName,
        {
          _errorStackArgName: stack,
          _errorMessageArgName: message,
          _errorContextArgName: context,
          _errorLibraryArgName: library,
          _errorTypeArgName: errorType,
        },
      );
    } catch (e) {
      // avoid propagating any errors that could cause an error loop!
      if (kDebugMode) {
        print('Failed to send error to Embrace: $e');
      }
    }
  }

  @override
  Future<LastRunEndState> getLastRunEndState() async {
    final lastRunEndState =
        await methodChannel.invokeMethod<int>(_getLastRunEndStateMethodName);
    switch (lastRunEndState) {
      case 1:
        return LastRunEndState.crash;
      case 2:
        return LastRunEndState.cleanExit;
      default:
        return LastRunEndState.invalid;
    }
  }
  // lib/method_channel_embrace.dart: 364, 373, 378, 380, 390

  /// Throws a [StateError] if the SDK has not been started.
  void throwIfNotStarted() {
    if (!isStarted) {
      throw StateError('Embrace SDK has not been started.');
    }
  }

  /// Callback used to process incoming method calls from the native method
  /// channel.
  @visibleForTesting
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      default:
        logInternalError(
          'Embrace MethodChannel received unknown MethodCall from host SDK.',
          call.method,
        );
        break;
    }
  }
}
