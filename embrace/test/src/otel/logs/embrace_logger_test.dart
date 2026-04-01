import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/logs/embrace_logger.dart';
// ignore: implementation_imports
import 'package:embrace/src/otel/logs/embrace_logger_provider.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbracePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EmbracePlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEmbracePlatform platform;
  late EmbraceLoggerProvider provider;
  late EmbraceLogger logger;

  setUp(() {
    platform = MockEmbracePlatform();
    EmbracePlatform.instance = platform;

    when(
      () => platform.logInfo(any(), any()),
    ).thenReturn(null);
    when(
      () => platform.logWarning(any(), any()),
    ).thenReturn(null);
    when(
      () => platform.logError(any(), any()),
    ).thenReturn(null);

    provider = EmbraceLoggerProvider(endpoint: '');
    logger = provider.getLogger('test');
  });

  // ignore: invalid_use_of_visible_for_testing_member
  tearDown(OTelAPI.reset);

  group('EmbraceLogger', () {
    test('emit with severity 5 (DEBUG) calls logInfo', () {
      logger.emit(severityNumber: Severity.DEBUG, body: 'debug msg');

      verify(() => platform.logInfo('debug msg', null)).called(1);
      verifyNever(() => platform.logWarning(any(), any()));
      verifyNever(() => platform.logError(any(), any()));
    });

    test('emit with severity 9 (INFO) calls logInfo', () {
      logger.emit(severityNumber: Severity.INFO, body: 'info msg');

      verify(() => platform.logInfo('info msg', null)).called(1);
      verifyNever(() => platform.logWarning(any(), any()));
      verifyNever(() => platform.logError(any(), any()));
    });

    test('emit with severity 13 (WARN) calls logWarning', () {
      logger.emit(severityNumber: Severity.WARN, body: 'warn msg');

      verify(() => platform.logWarning('warn msg', null)).called(1);
      verifyNever(() => platform.logInfo(any(), any()));
      verifyNever(() => platform.logError(any(), any()));
    });

    test('emit with severity 17 (ERROR) calls logError', () {
      logger.emit(severityNumber: Severity.ERROR, body: 'error msg');

      verify(() => platform.logError('error msg', null)).called(1);
      verifyNever(() => platform.logInfo(any(), any()));
      verifyNever(() => platform.logWarning(any(), any()));
    });

    test('emit with severity 21 (FATAL) calls logError', () {
      logger.emit(severityNumber: Severity.FATAL, body: 'fatal msg');

      verify(() => platform.logError('fatal msg', null)).called(1);
      verifyNever(() => platform.logInfo(any(), any()));
      verifyNever(() => platform.logWarning(any(), any()));
    });

    test('emit forwards body as message string', () {
      logger.emit(severityNumber: Severity.INFO, body: 'the message');

      verify(() => platform.logInfo('the message', null)).called(1);
    });

    test('emit when enabled is false is a no-op', () async {
      await provider.shutdown();

      logger.emit(severityNumber: Severity.INFO, body: 'should not emit');

      verifyNever(() => platform.logInfo(any(), any()));
      verifyNever(() => platform.logWarning(any(), any()));
      verifyNever(() => platform.logError(any(), any()));
    });
  });
}
