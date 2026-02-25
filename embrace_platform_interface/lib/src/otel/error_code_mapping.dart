import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';

/// Bidirectional mapping between [ErrorCode] and OTel [SpanStatusCode].
///
/// Forward mapping ([toSpanStatus]):
/// - `null` → [SpanStatusCode.Ok]
/// - [ErrorCode.failure] → [SpanStatusCode.Error]
/// - [ErrorCode.abandon] → [SpanStatusCode.Error]
/// - [ErrorCode.unknown] → [SpanStatusCode.Error]
///
/// Reverse mapping ([toErrorCode]):
/// - [SpanStatusCode.Ok] → `null`
/// - [SpanStatusCode.Unset] → `null`
/// - [SpanStatusCode.Error] → [ErrorCode.failure] (lossy: all Error codes map
///   to `failure` by convention since the original reason cannot be recovered)
abstract final class ErrorCodeMapping {
  /// Maps an [ErrorCode] to an OTel [SpanStatusCode].
  ///
  /// A `null` [errorCode] (no error) maps to [SpanStatusCode.Ok].
  /// Any non-null [ErrorCode] maps to [SpanStatusCode.Error].
  static SpanStatusCode toSpanStatus(ErrorCode? errorCode) {
    if (errorCode == null) return SpanStatusCode.Ok;
    return SpanStatusCode.Error;
  }

  /// Maps an OTel [SpanStatusCode] to an [ErrorCode].
  ///
  /// [SpanStatusCode.Ok] and [SpanStatusCode.Unset] map to `null` (no error).
  /// [SpanStatusCode.Error] maps to [ErrorCode.failure] by convention, since
  /// the original [ErrorCode] cannot be recovered from the status alone.
  static ErrorCode? toErrorCode(SpanStatusCode status) {
    if (status == SpanStatusCode.Error) return ErrorCode.failure;
    return null;
  }
}
