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
  Future<String?> get traceId => Future.value(null);
}

class FakeRoute extends Fake implements Route<dynamic> {
  FakeRoute(this.settings);

  @override
  final RouteSettings settings;
}
