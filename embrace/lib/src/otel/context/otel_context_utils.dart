import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:meta/meta.dart';

/// Static helpers for managing OTel [Context] within Embrace.
///
/// All context push/restore logic lives here so callers don't manipulate
/// [Context.current] directly.
@internal
class OTelContextUtils {
  OTelContextUtils._();

  /// Returns the span currently active in [Context.current], or `null` if
  /// no span is active or OTel has not been initialized.
  static APISpan? currentSpan() {
    if (OTelFactory.otelFactory == null) return null;
    return Context.current.span;
  }

  /// Returns the [SpanContext] of the currently active span, or `null` if
  /// no span is active or OTel has not been initialized.
  static SpanContext? currentSpanContext() {
    if (OTelFactory.otelFactory == null) return null;
    return Context.current.spanContext;
  }
}
