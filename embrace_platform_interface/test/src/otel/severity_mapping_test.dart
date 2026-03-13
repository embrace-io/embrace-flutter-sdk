import 'package:embrace_platform_interface/src/otel/severity_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeverityMapping.toSeverityNumber', () {
    test('info maps to 9', () {
      expect(SeverityMapping.toSeverityNumber(EmbraceSeverity.info), 9);
    });

    test('warning maps to 13', () {
      expect(SeverityMapping.toSeverityNumber(EmbraceSeverity.warning), 13);
    });

    test('error maps to 17', () {
      expect(SeverityMapping.toSeverityNumber(EmbraceSeverity.error), 17);
    });

    test('handledDartError maps to 17', () {
      expect(
        SeverityMapping.toSeverityNumber(EmbraceSeverity.handledDartError),
        17,
      );
    });

    test('dartError maps to 21', () {
      expect(SeverityMapping.toSeverityNumber(EmbraceSeverity.dartError), 21);
    });
  });

  group('SeverityMapping.fromLogMethodName', () {
    test('logInfo maps to info', () {
      expect(
        SeverityMapping.fromLogMethodName('logInfo'),
        EmbraceSeverity.info,
      );
    });

    test('logWarning maps to warning', () {
      expect(
        SeverityMapping.fromLogMethodName('logWarning'),
        EmbraceSeverity.warning,
      );
    });

    test('logError maps to error', () {
      expect(
        SeverityMapping.fromLogMethodName('logError'),
        EmbraceSeverity.error,
      );
    });

    test('logDartError maps to dartError', () {
      expect(
        SeverityMapping.fromLogMethodName('logDartError'),
        EmbraceSeverity.dartError,
      );
    });

    test('logHandledDartError maps to handledDartError', () {
      expect(
        SeverityMapping.fromLogMethodName('logHandledDartError'),
        EmbraceSeverity.handledDartError,
      );
    });

    test('unknown method name returns null', () {
      expect(SeverityMapping.fromLogMethodName('unknownMethod'), isNull);
    });

    test('empty string returns null', () {
      expect(SeverityMapping.fromLogMethodName(''), isNull);
    });
  });
}
