import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';

/// Stores and restores [OTelSpanAdapter] in OTel [Context].
///
/// Uses a typed [ContextKey] to track the "current span" in OTel's zone-aware
/// [Context], enabling automatic parent-child relationships when the explicit
/// `parent` parameter is omitted on `startSpan`.
///
/// Follows the OTel attach/detach scope pattern: [setCurrent] returns the full
/// previous [Context] (the scope token), and [restore] reinstates it entirely.
/// This ensures any keys added by other OTel components between span start and
/// stop are not inadvertently dropped.
///
/// Instantiate once and inject where needed. Each instance owns its own
/// [ContextKey], so two instances do not interfere with each other — this
/// makes test isolation straightforward: create a fresh instance in setUp.
///
/// Usage pattern:
/// ```dart
/// // On span start:
/// final previousContext = contextUtils.setCurrent(adapter);
/// spanImpl.attachOTelContext(adapter, previousContext, contextUtils);
///
/// // On span end (inside EmbraceSpanImpl.stop):
/// adapter.markEnded(errorCode: errorCode, endTimeMs: endTimeMs);
/// contextUtils.restore(previousContext);
/// ```
class OTelContextUtils {
  /// Creates a new [OTelContextUtils] with its own isolated [ContextKey].
  OTelContextUtils()
      : _spanKey = ContextKeyCreate.create<OTelSpanAdapter>(
          'embrace.current_span',
          ContextKey.generateContextKeyId(),
        );

  final ContextKey<OTelSpanAdapter> _spanKey;

  /// Whether [Context.current] has been bootstrapped for use without a
  /// fully initialized [OTelFactory].
  bool _bootstrapped = false;

  /// Returns the current [Context], bootstrapping an empty one on first use
  /// if [OTelFactory] has not yet been initialized.
  Context _safeCurrentContext() {
    if (!_bootstrapped && OTelFactory.otelFactory == null) {
      _bootstrapped = true;
      Context.current = ContextCreate.create();
    }
    return Context.current;
  }

  /// Returns the current [OTelSpanAdapter] from [Context.current], or null.
  OTelSpanAdapter? currentSpan() => _safeCurrentContext().get(_spanKey);

  /// Stores [adapter] in [Context.current] as the current span.
  ///
  /// Returns the previous [Context] before [adapter] was attached. Pass this
  /// to [restore] when the span ends to reinstate the full previous context,
  /// following the OTel scope/token pattern.
  Context setCurrent(OTelSpanAdapter adapter) {
    final previous = _safeCurrentContext();
    Context.current = previous.copyWith(_spanKey, adapter);
    return previous;
  }

  /// Restores [previous] as [Context.current].
  ///
  /// Pass the [Context] returned by [setCurrent] to undo the attach and
  /// reinstate the full context that was active before the span started.
  // ignore: use_setters_to_change_properties
  void restore(Context previous) {
    Context.current = previous;
  }

  /// Generates a W3C traceparent string from the current span in Context.
  ///
  /// Returns null if there is no current span or if its [SpanContext] is
  /// invalid (e.g. all-zeros trace/span IDs).
  ///
  /// Format: `{version}-{traceId}-{spanId}-{traceFlags}`
  /// Example: `00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01`
  String? currentTraceparent() {
    final adapter = currentSpan();
    if (adapter == null) return null;
    final spanContext = adapter.spanContext;
    if (!spanContext.isValid) return null;
    final flags = spanContext.traceFlags.isSampled ? '01' : '00';
    return '00-${spanContext.traceId.hexString}-'
        '${spanContext.spanId.hexString}-$flags';
  }
}
