import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/src/otel/error_code_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorCodeMapping.toSpanStatus', () {
    test('null maps to Ok', () {
      expect(ErrorCodeMapping.toSpanStatus(null), SpanStatusCode.Ok);
    });

    test('failure maps to Error', () {
      expect(
        ErrorCodeMapping.toSpanStatus(ErrorCode.failure),
        SpanStatusCode.Error,
      );
    });

    test('abandon maps to Error', () {
      expect(
        ErrorCodeMapping.toSpanStatus(ErrorCode.abandon),
        SpanStatusCode.Error,
      );
    });

    test('unknown maps to Error', () {
      expect(
        ErrorCodeMapping.toSpanStatus(ErrorCode.unknown),
        SpanStatusCode.Error,
      );
    });
  });

  group('ErrorCodeMapping.toErrorCode', () {
    test('Ok maps to null', () {
      expect(ErrorCodeMapping.toErrorCode(SpanStatusCode.Ok), isNull);
    });

    test('Unset maps to null', () {
      expect(ErrorCodeMapping.toErrorCode(SpanStatusCode.Unset), isNull);
    });

    test('Error maps to failure by convention', () {
      expect(
        ErrorCodeMapping.toErrorCode(SpanStatusCode.Error),
        ErrorCode.failure,
      );
    });
  });
}
