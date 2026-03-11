import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';

/// Stores and restores [OTelSpanAdapter] in OTel [Context].
///
/// Uses a typed [ContextKey] to track the "current span" in OTel's zone-aware
/// [Context], enabling automatic parent-child relationships when the explicit
/// `parent` parameter is omitted on `startSpan`.
///
/// Follows the OTel attach/detach scope pattern: call [getCurrent] before
/// [setCurrent] to capture the scope token, then pass it to [restore] when the
/// span ends. [restore] reinstates the full previous [Context], ensuring any
/// keys added by other OTel components between span start and stop are not
/// inadvertently dropped.
///
/// Instantiate once and inject where needed. Each instance owns its own
/// [ContextKey], so two instances do not interfere with each other — this
/// makes test isolation straightforward: create a fresh instance in setUp.
///
/// Usage pattern:
/// ```dart
/// // On span start:
/// final previousContext = contextUtils.getCurrent();
/// contextUtils.setCurrent(adapter);
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

  /// Returns the active [Context] (the scope token to pass to [restore] later).
  ///
  /// **Must be called in the same synchronous scope as [setCurrent].** Adding
  /// an `await` between [getCurrent] and [setCurrent] silently introduces a
  /// concurrency bug: another fiber may change [Context.current] in between.
  Context getCurrent() => _safeCurrentContext();

  /// Stores [adapter] in [Context.current] as the current span.
  ///
  /// Also stores the span's [SpanContext] in the standard OTel
  /// [Context.spanContext] slot (via [Context.withSpanContext]) when the
  /// adapter's span context is valid. This allows standard OTel propagators
  /// (e.g. `W3CTraceContextPropagator`) to inject the traceparent header
  /// directly from [Context.current] without additional bridging.
  ///
  /// Call [getCurrent] before this to capture the previous [Context], then
  /// pass it to [restore] when the span ends to follow the OTel scope/token
  /// pattern.
  void setCurrent(OTelSpanAdapter adapter) {
    final current = _safeCurrentContext();
    var next = current.copyWith(_spanKey, adapter);
    if (adapter.spanContext.isValid) {
      next = next.withSpanContext(adapter.spanContext);
    }
    Context.current = next;
  }

  /// Restores [previous] as [Context.current].
  ///
  /// Pass the [Context] returned by [getCurrent] to undo the attach and
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
