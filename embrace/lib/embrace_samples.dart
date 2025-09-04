import 'dart:async';

import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/foundation.dart';

export 'package:embrace_platform_interface/http_method.dart' show HttpMethod;

/// Provides sample code to trigger errors in Embrace.
class EmbraceSamples {
  static EmbracePlatform get _platform => EmbracePlatform.instance;

  /// Invokes [triggerAnr] on the underlying [EmbracePlatform.instance].
  static void triggerAnr() {
    _platform.triggerAnr();
  }

  /// Invokes [triggerNativeSdkError]
  /// on the underlying [EmbracePlatform.instance].
  static void triggerNativeSdkError() {
    _platform.triggerNativeSdkError();
  }

  /// Invokes [triggerRaisedSignal]
  /// on the underlying [EmbracePlatform.instance].
  static void triggerRaisedSignal() {
    _platform.triggerRaisedSignal();
  }

  /// Invokes [triggerMethodChannelError]
  /// on the underlying [EmbracePlatform.instance].
  static void triggerMethodChannelError() {
    if (kDebugMode) print('Starting method channel err!');
    _platform.triggerMethodChannelError();
  }

  /// Triggers a caught exception.
  static void triggerCaughtException() {
    try {
      throw Exception('Embrace sample: caught exception');
    } catch (exc, stack) {
      if (kDebugMode) {
        print(
          'Exception message: $exc, '
          'Stacktrace:\n$stack',
        );
      }
    }
  }

  /// Throws a [FormatException].
  static void triggerUncaughtException() {
    throw const FormatException(
      'Embrace sample: uncaught formatting exception',
    );
  }

  /// Throws a [StateError].
  static void triggerUncaughtError() {
    throw StateError('Embrace sample: illegal state, throwing error!');
  }

  /// Throws a [String] object.
  static void triggerUncaughtObject() {
    // ignore: only_throw_errors
    throw 'Embrace sample: throwing a string';
  }

  /// Throws an [AssertionError].
  static void triggerAssert() {
    assert(false == true, 'Embrace sample: asserting true is false');
  }

  /// Throws an uncaught exception.
  static Future<void> triggerUncaughtExceptionAsync() async {
    await Future(() async {
      throw Exception('Embrace sample: Error in async function');
    });
  }
}
