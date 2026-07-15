import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

class MockEmbrace extends Mock implements Embrace {}

class MockEmbraceSpan extends Mock implements EmbraceSpan {
  @override
  String get id => 'mock-span-id';

  @override
  Future<String?> get traceId => Future.value();
}

class FakeRoute extends Fake implements TransitionRoute<dynamic> {
  FakeRoute(this.settings, {Animation<double>? animation})
      : animation = animation ?? FakeAnimation();

  @override
  final RouteSettings settings;

  @override
  final Animation<double>? animation;
}

class FakeAnimation extends Fake implements Animation<double> {
  FakeAnimation({this.status = AnimationStatus.forward});

  @override
  AnimationStatus status;

  final List<AnimationStatusListener> _listeners = [];

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _listeners.remove(listener);
  }

  void fireStatus(AnimationStatus newStatus) {
    status = newStatus;
    for (final listener in List<AnimationStatusListener>.of(_listeners)) {
      listener(newStatus);
    }
  }
}
