import 'dart:async';

import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

EmbraceLifecycleObserver? _activeObserver;

@internal
// Called by Embrace.disable() to tear down lifecycle observation.
void stopActiveLifecycleObserver() {
  _activeObserver?.stop();
}

/// A [WidgetsBindingObserver] that tracks app foreground/background lifecycle.
class EmbraceLifecycleObserver with WidgetsBindingObserver {
  EmbraceSpan? _backgroundSpan;
  bool _isBackground = false;

  /// Begins observing app lifecycle changes.
  void start() {
    _activeObserver = this;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stops observing app lifecycle changes and closes any open background
  /// span.
  void stop() {
    if (_activeObserver == this) _activeObserver = null;
    WidgetsBinding.instance.removeObserver(this);
    _isBackground = false;
    _stopBackgroundSpan();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onPaused();
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.detached:
        _onDetached();
      case _:
        break;
    }
  }

  void _onPaused() {
    if (_isBackground) return;
    _isBackground = true;
    Embrace.instance.startSpan('emb-app-background').then(
      (span) {
        _backgroundSpan = span;
        if (!_isBackground) {
          _stopBackgroundSpan();
        }
      },
      onError: (_, __) {},
    );
  }

  void _onResumed() {
    _isBackground = false;
    _stopBackgroundSpan();
  }

  void _onDetached() {
    _isBackground = false;
    _stopBackgroundSpan();
  }

  void _stopBackgroundSpan() {
    final span = _backgroundSpan;
    _backgroundSpan = null;
    if (span != null) {
      unawaited(span.stop());
    }
  }
}
