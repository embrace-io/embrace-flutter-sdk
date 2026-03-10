import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';

/// Stores and restores [OTelSpanAdapter] in OTel [Context].
///
/// Uses a typed [ContextKey] to track the "current span" in OTel's zone-aware
/// [Context], enabling automatic parent-child relationships when the explicit
/// `parent` parameter is omitted on `startSpan`.
///
/// [OTelSpanAdapter.isRecording] is used as the sentinel for "active in
/// context": a span whose [OTelSpanAdapter.markEnded] has been called is
/// considered inactive even if it is still stored in the context map.
///
/// Instantiate once and inject where needed. Each instance owns its own
/// [ContextKey], so two instances do not interfere with each other — this
/// makes test isolation straightforward: create a fresh instance in setUp.
///
/// Usage pattern:
/// ```dart
/// // On span start:
/// final previous = contextUtils.setCurrent(adapter);
/// spanImpl.attachOTelContext(adapter, previous, contextUtils);
///
/// // On span end (inside EmbraceSpanImpl.stop):
/// adapter.markEnded(errorCode: errorCode, endTimeMs: endTimeMs);
/// contextUtils.restore(previousAdapter);
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
      final ctx = ContextCreate.create();
      Context.current = ctx;
      return ctx;
    }
    return Context.current;
  }

  /// Returns the current [OTelSpanAdapter] from [Context.current], or null.
  ///
  /// Returns null if no span is stored in context, or if the stored span's
  /// [OTelSpanAdapter.isRecording] is false (i.e. it has been ended).
  OTelSpanAdapter? currentSpan() {
    final adapter = _safeCurrentContext().get(_spanKey);
    if (adapter == null || !adapter.isRecording) return null;
    return adapter;
  }

  /// Stores [adapter] in [Context.current] as the current span.
  ///
  /// Returns the previous [OTelSpanAdapter] (may be null if no span was
  /// active). Pass the returned value to [restore] when the span ends to
  /// reinstate the parent span.
  OTelSpanAdapter? setCurrent(OTelSpanAdapter adapter) {
    final ctx = _safeCurrentContext();
    final previous = ctx.get(_spanKey);
    Context.current = ctx.copyWith(_spanKey, adapter);
    return previous;
  }

  /// Restores [previous] as the current span in [Context.current].
  ///
  /// If [previous] is null, this is a no-op: [currentSpan] will return null
  /// because the span still stored in context has already been marked ended
  /// (via [OTelSpanAdapter.markEnded]) before this call.
  ///
  /// Always call [OTelSpanAdapter.markEnded] on the current span before
  /// calling [restore], so that [currentSpan] correctly returns null when
  /// there is no active parent to restore to.
  void restore(OTelSpanAdapter? previous) {
    if (previous == null) return;
    final ctx = _safeCurrentContext();
    Context.current = ctx.copyWith(_spanKey, previous);
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
