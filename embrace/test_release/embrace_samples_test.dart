// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:embrace/embrace_samples.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../test/helpers/helpers.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Release',
    () {
      group('EmbraceSamples', () {
        late EmbracePlatform embracePlatform;

        setUp(() {
          embracePlatform = MockEmbracePlatform();
          EmbracePlatform.instance = embracePlatform;
        });

        group(
          'triggerMethodChannelError',
          () {
            test('does not log a message on release mode', () {
              when(embracePlatform.triggerMethodChannelError)
                  .thenAnswer((_) {});
              final printed =
                  getPrints(EmbraceSamples.triggerMethodChannelError);
              expect(printed, isEmpty);
            });
          },
        );

        group(
          'triggerCaughtException',
          () {
            test('does not log a message on release mode', () {
              final printed = getPrints(EmbraceSamples.triggerCaughtException);
              expect(printed, isEmpty);
            });
          },
        );
      });
    },
    skip: !kReleaseMode,
  );
}
