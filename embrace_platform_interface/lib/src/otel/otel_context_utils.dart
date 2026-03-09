import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';

/// Nullable wrapper so a null adapter can be stored in a non-nullable
/// [ContextKey].
class _SpanHolder {
  const _SpanHolder(this.adapter);

  final OTelSpanAdapter? adapter;
}

/// Utilities for storing and restoring [OTelSpanAdapter] in OTel [Context].
///
/// Uses a typed [ContextKey] to track the "current span" in OTel's zone-aware
/// [Context], enabling automatic parent-child relationships when the explicit
/// `parent` parameter is omitted on `startSpan`.
///
/// Usage pattern:
/// ```dart
/// // On span start:
/// final previous = OTelContextUtils.setCurrent(adapter);
/// spanImpl.attachOTelContext(adapter, previous);
///
/// // On span end (inside EmbraceSpanImpl.stop):
/// OTelContextUtils.restore(previousAdapter);
/// ```
class OTelContextUtils {
  OTelContextUtils._();

  static final ContextKey<_SpanHolder> _spanKey =
      ContextKeyCreate.create<_SpanHolder>(
    'embrace.current_span',
    ContextKey.generateContextKeyId(),
  );

  /// Whether [Context.current] has been bootstrapped for use without a
  /// fully initialized [OTelFactory].
  ///
  /// Once set to true, [Context.current] is guaranteed to have a non-root
  /// value and can be read safely.
  static bool _bootstrapped = false;

  /// Returns the current [Context], bootstrapping an empty one on first use
  /// if [OTelFactory] has not yet been initialized.
  ///
  /// After the first call (or after [Context.resetCurrent] is called in
  /// tests), [Context.current] will always have a non-null value and can be
  /// read without going to [Context.root].
  static Context _safeCurrentContext() {
    if (!_bootstrapped && OTelFactory.otelFactory == null) {
      _bootstrapped = true;
      final ctx = ContextCreate.create();
      Context.current = ctx;
      return ctx;
    }
    return Context.current;
  }

  /// Returns the current [OTelSpanAdapter] from [Context.current], or null.
  static OTelSpanAdapter? currentSpan() =>
      _safeCurrentContext().get(_spanKey)?.adapter;

  /// Stores [adapter] in [Context.current] as the current span.
  ///
  /// Returns the previous [OTelSpanAdapter] (may be null if no span was
  /// active). Pass the returned value to [restore] when the span ends to
  /// reinstate the parent span.
  static OTelSpanAdapter? setCurrent(OTelSpanAdapter adapter) {
    final ctx = _safeCurrentContext();
    final previous = ctx.get(_spanKey)?.adapter;
    Context.current = ctx.copyWith(_spanKey, _SpanHolder(adapter));
    return previous;
  }

  /// Restores [previous] as the current span in [Context.current].
  ///
  /// If [previous] is null, the current span is cleared. Pass the value
  /// returned by [setCurrent] to restore the context on span end.
  static void restore(OTelSpanAdapter? previous) {
    final ctx = _safeCurrentContext();
    Context.current = ctx.copyWith(_spanKey, _SpanHolder(previous));
  }
}
