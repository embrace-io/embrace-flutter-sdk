import 'dart:async';

import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/http_method.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:embrace_platform_interface/src/sdk_version.dart';
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
  static const String _addBreadcrumbMethodName = 'addBreadcrumb';
  static const String _logPushNotificationMethodName = 'logPushNotification';
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
  static const String _addUserPersonaMethodName = 'addUserPersona';
  static const String _clearUserIdentifierMethodName = 'clearUserIdentifier';
  static const String _clearUserNameMethodName = 'clearUserName';
  static const String _clearUserEmailMethodName = 'clearUserEmail';
  static const String _clearUserAsPayerMethodName = 'clearUserAsPayer';
  static const String _clearUserPersonaMethodName = 'clearUserPersona';
  static const String _clearAllUserPersonasMethodName = 'clearAllUserPersonas';
  static const String _logNetworkRequestMethodName = 'logNetworkRequest';
  static const String _generateW3cTraceparentMethodName =
      'generateW3cTraceparent';
  static const String _logInternalErrorMethodName = 'logInternalError';
  static const String _logDartErrorMethodName = 'logDartError';
  static const String _addSessionPropertyMethodName = 'addSessionProperty';
  static const String _removeSessionPropertyMethodName =
      'removeSessionProperty';
  static const String _endSessionMethodName = 'endSession';
  static const String _getLastRunEndStateMethodName = 'getLastRunEndState';
  static const String _getCurrentSessionIdMethodName = 'getCurrentSessionId';
  static const String _startSpanMethodName = 'startSpan';
  static const String _stopSpanMethodName = 'stopSpan';
  static const String _addSpanEventMethodName = 'addSpanEvent';
  static const String _addSpanAttributeMethodName = 'addSpanAttribute';
  static const String _recordCompletedSpanMethodName = 'recordCompletedSpan';
  static const String _getTraceIdMethodName = 'getTraceId';

  // Parameter Names
  static const String _propertiesArgName = 'properties';
  static const String _messageArgName = 'message';
  static const String _nameArgName = 'name';
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
  static const String _w3cTraceparentArgName = 'traceParent';
  static const String _detailsArgName = 'details';
  static const String _embraceFlutterSdkVersionArgName =
      'embraceFlutterSdkVersion';
  static const String _dartRuntimeVersionArgName = 'dartRuntimeVersion';
  static const String _errorStackArgName = 'stack';
  static const String _errorMessageArgName = 'message';
  static const String _errorContextArgName = 'context';
  static const String _errorLibraryArgName = 'library';
  static const String _errorTypeArgName = 'type';
  static const String _errorWasHandledArgName = 'wasHandled';
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
  static const String _parentSpanIdArgName = 'parentSpanId';
  static const String _spanIdArgName = 'spanId';
  static const String _errorCodeArgName = 'errorCode';
  static const String _startTimeMsArgName = 'startTimeMs';
  static const String _endTimeMsArgName = 'endTimeMs';
  static const String _timestampMsArgName = 'timestampMs';
  static const String _eventsArgName = 'events';
  static const String _attributesArgName = 'attributes';

  /// Minimum Embrace Android SDK version compatible with this version of
  /// the Embrace Flutter SDK
  static const String minimumAndroidVersion = '8.1.0';

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

    // Check android version
    if (kDebugMode && _platform.isAndroid) {
      final nativeAndroidVersionStr = await _getNativeSdkVersion();
      if (nativeAndroidVersionStr != null) {
        final nativeVersion = SdkVersion(nativeAndroidVersionStr);
        if (nativeVersion.isLowerThan(minimumAndroidVersion)) {
          if (kDebugMode) {
            print('WARNING: You are using Embrace Android SDK '
                '$nativeAndroidVersionStr which is lower than the minimum '
                '$minimumAndroidVersion. '
                'See https://embrace.io/docs/flutter/integration/add-embrace-sdk/#android-setup '
                'for more information.');
          }
          logWarning(
            'Embrace Android SDK version ($nativeAndroidVersionStr) is lower '
            'than required minimum $minimumAndroidVersion.',
            null,
          );
        }
      }
    }

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
          'The Embrace SDK was not started in Android/iOS native code '
          'and it will be initialized by the Flutter SDK. We '
          'recommend adding native initialization to report more accurate '
          'start up times (see '
          'https://embrace.io/docs/flutter/integration/session-reporting/#add-the-android-sdk-start-call '
          'for Android and '
          'https://embrace.io/docs/flutter/integration/session-reporting/#add-the-ios-sdk-start-call '
          'for iOS).',
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
  void logBreadcrumb(String message) {
    throwIfNotStarted();
    methodChannel
        .invokeMethod(_addBreadcrumbMethodName, {_messageArgName: message});
  }

  @override
  void addBreadcrumb(String message) {
    throwIfNotStarted();
    methodChannel
        .invokeMethod(_addBreadcrumbMethodName, {_messageArgName: message});
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
      _hasDataArgName: hasData,
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
  void logWarning(String message, Map<String, String>? properties) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_logWarningMethodName, {
      _messageArgName: message,
      _propertiesArgName: properties,
    });
  }

  @override
  void logError(
    String message,
    Map<String, String>? properties,
  ) {
    throwIfNotStarted();
    methodChannel.invokeMethod(_logErrorMethodName, {
      _messageArgName: message,
      _propertiesArgName: properties,
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
    String? w3cTraceparent,
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
      _w3cTraceparentArgName: w3cTraceparent,
    });
  }

  @override
  Future<String?> generateW3cTraceparent(
    String? traceId,
    String? spanId,
  ) async {
    throwIfNotStarted();
    return methodChannel.invokeMethod(_generateW3cTraceparentMethodName, {
      _traceIdArgName: traceId,
      _spanIdArgName: spanId,
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
  void addUserPersona(String persona) {
    throwIfNotStarted();
    methodChannel.invokeMethod(
      _addUserPersonaMethodName,
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
  void logInternalError(String message, String details) {
    // don't fail when logging internal errors if not started
    if (!isStarted) {
      return;
    }
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
    bool wasHandled = false,
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
          _errorWasHandledArgName: wasHandled,
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

  @override
  Future<String?> getCurrentSessionId() async {
    return methodChannel.invokeMethod<String?>(_getCurrentSessionIdMethodName);
  }
  // lib/method_channel_embrace.dart: 364, 373, 378, 380, 390

  @override
  Future<String?> startSpan(
    String name, {
    String? parentSpanId,
    int? startTimeMs,
  }) async {
    throwIfNotStarted();
    return methodChannel.invokeMethod(_startSpanMethodName, {
      _nameArgName: name,
      _parentSpanIdArgName: parentSpanId,
      _startTimeMsArgName: startTimeMs,
    });
  }

  @override
  Future<bool> stopSpan(
    String spanId, {
    ErrorCode? errorCode,
    int? endTimeMs,
  }) async {
    throwIfNotStarted();
    return await methodChannel.invokeMethod(_stopSpanMethodName, {
      _spanIdArgName: spanId,
      _errorCodeArgName: errorCode?.name,
      _endTimeMsArgName: endTimeMs,
    }) as bool;
  }

  @override
  Future<bool> addSpanEvent(
    String spanId,
    String name, {
    int? timestampMs,
    Map<String, String>? attributes,
  }) async {
    throwIfNotStarted();
    return await methodChannel.invokeMethod(_addSpanEventMethodName, {
      _spanIdArgName: spanId,
      _nameArgName: name,
      _timestampMsArgName: timestampMs,
      _attributesArgName: attributes,
    }) as bool;
  }

  @override
  Future<bool> addSpanAttribute(String spanId, String key, String value) async {
    throwIfNotStarted();
    return await methodChannel.invokeMethod(_addSpanAttributeMethodName, {
      _spanIdArgName: spanId,
      _keyArgName: key,
      _valueArgName: value,
    }) as bool;
  }

  @override
  Future<bool> recordCompletedSpan(
    String name,
    int startTimeMs,
    int endTimeMs, {
    ErrorCode? errorCode,
    String? parentSpanId,
    Map<String, String>? attributes,
    List<Map<String, dynamic>>? events,
  }) async {
    throwIfNotStarted();
    return await methodChannel.invokeMethod(_recordCompletedSpanMethodName, {
      _nameArgName: name,
      _startTimeMsArgName: startTimeMs,
      _endTimeMsArgName: endTimeMs,
      _errorCodeArgName: errorCode?.name,
      _parentSpanIdArgName: parentSpanId,
      _attributesArgName: attributes,
      _eventsArgName: events,
    }) as bool;
  }

  @override
  Future<T> recordSpan<T>(
    String name, {
    String? parentSpanId,
    Map<String, String>? attributes,
    List<Map<String, dynamic>>? events,
    required Future<T> Function() code,
  }) async {
    throwIfNotStarted();
    final startTimeMs = DateTime.now().millisecondsSinceEpoch;
    final spanId =
        await methodChannel.invokeMethod<String>(_startSpanMethodName, {
      _nameArgName: name,
      _parentSpanIdArgName: parentSpanId,
      _startTimeArgName: startTimeMs,
    });
    final result = await code();
    final endTimeMs = DateTime.now().millisecondsSinceEpoch;
    await methodChannel.invokeMethod(_stopSpanMethodName, {
      _spanIdArgName: spanId,
      _parentSpanIdArgName: parentSpanId,
      _endTimeMsArgName: endTimeMs,
    });
    return result;
  }

  @override
  Future<String?> getTraceId(String spanId) async {
    throwIfNotStarted();
    return methodChannel.invokeMethod<String>(_getTraceIdMethodName, {
      _spanIdArgName: spanId,
    });
  }

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

  /// Gets the semver version of the underlying native Embrace SDK
  Future<String?> _getNativeSdkVersion() async {
    return methodChannel.invokeMethod<String?>(
      'getSdkVersion',
    );
  }
}
