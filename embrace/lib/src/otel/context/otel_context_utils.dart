import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:meta/meta.dart';

/// Static helpers for managing OTel [Context] within Embrace.
///
/// All context push/restore logic lives here so callers don't manipulate
/// [Context.current] directly.
@internal
class OTelContextUtils {
  OTelContextUtils._();

  /// Makes [span] the active span in [Context.current] and returns the
  /// context that was active before the push.
  static Context attachSpan(APISpan span) {
    final previous = Context.current;
    Context.current = previous.withSpan(span);
    return previous;
  }

  /// Restores a previously saved context as [Context.current].
  // ignore: use_setters_to_change_properties
  static void restore(Context previous) {
    Context.current = previous;
  }

  /// Returns the span currently active in [Context.current], or `null` if
  /// no span is active.
  static APISpan? currentSpan() => Context.current.span;

  /// Returns the [SpanContext] of the currently active span, or `null` if
  /// no span is active.
  static SpanContext? currentSpanContext() => Context.current.spanContext;
}
