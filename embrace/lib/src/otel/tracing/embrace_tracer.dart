import 'dart:async';

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/context/otel_context_utils.dart';
import 'package:embrace/src/otel/tracing/embrace_otel_span.dart';
import 'package:embrace/src/otel/tracing/embrace_tracer_provider.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:meta/meta.dart';

/// Embrace implementation of [APITracer].
///
/// Overrides [startSpan] and [createSpan] to forward span creation to the
/// native Embrace SDK via [EmbracePlatform] and return an [EmbraceOTelSpan]
/// that routes subsequent operations through the platform channel.
///
/// When [enabled] is false, both methods return a no-op span without calling
/// the platform.
@internal
class EmbraceTracer implements APITracer {
  /// Creates an [EmbraceTracer] backed by [provider].
  EmbraceTracer({required EmbraceTracerProvider provider})
      : _provider = provider,
        _instrumentationScope = OTelAPI.instrumentationScope(name: 'embrace');

  final EmbraceTracerProvider _provider;
  final InstrumentationScope _instrumentationScope;
  Attributes? _attributes;

  bool get enabled => _provider.enabled && !_provider.isShutdown;

  @override
  bool isEnabled({SpanKind? kind, Context? context}) => enabled;

  @override
  APISpan startSpan(
    String name, {
    Context? context,
    bool root = false,
    SpanKind kind = SpanKind.internal,
    Attributes? attributes,
    List<SpanLink>? links,
    DateTime? startTime,
    bool? isRecording = true,
  }) =>
      createSpan(
        name: name,
        context: context,
        root: root,
        kind: kind,
        attributes: attributes,
        links: links,
        startTime: startTime,
        isRecording: isRecording,
      );

  @override
  APISpan createSpan({
    required String name,
    SpanKind kind = SpanKind.internal,
    Attributes? attributes,
    List<SpanLink>? links,
    List<SpanEvent>? spanEvents,
    DateTime? startTime,
    bool? isRecording,
    Context? context,
    bool root = false,
  }) {
    final parent = root
        ? (parentSpanContext: null, parentSpan: null)
        : _resolveParent(context ?? Context.current);

    if (!enabled) {
      return OTelAPI.nonRecordingSpan(
        parent.parentSpanContext ?? OTelAPI.spanContextInvalid(),
      );
    }

    final nativeSpanId = EmbracePlatform.instance.startSpan(
      name,
      parentSpanId: parent.parentSpan?.spanContext.spanId.toString(),
      startTimeMs: startTime?.millisecondsSinceEpoch,
    );

    final span = EmbraceOTelSpan(
      name: name,
      nativeSpanId: nativeSpanId,
      spanContext: _buildSpanContext(parent.parentSpanContext),
      instrumentationScope: _instrumentationScope,
      parentSpan: parent.parentSpan,
      kind: kind,
      startTime: startTime,
    );

    if (attributes != null) span.addAttributes(attributes);
    links?.forEach(span.addSpanLink);
    spanEvents?.forEach(span.addEvent);

    return span;
  }

  @override
  String get name => _instrumentationScope.name;

  @override
  String? get version => _instrumentationScope.version;

  @override
  String? get schemaUrl => _instrumentationScope.schemaUrl;

  @override
  Attributes? get attributes => _attributes;

  @override
  set attributes(Attributes? value) => _attributes = value;

  @override
  APISpan? get currentSpan => OTelContextUtils.currentSpan();

  @override
  TimeProvider get timeProvider => defaultTimeProvider;

  @override
  T withSpan<T>(APISpan span, T Function() fn) =>
      Context.current.withSpan(span).runSync(fn);

  @override
  Future<T> withSpanAsync<T>(APISpan span, Future<T> Function() fn) =>
      Context.current.withSpan(span).run(fn);

  /// Resolves the parent for a span created in [context], using the same
  /// precedence as [APITracer.createSpan]: remote span context, then local
  /// span, then non-remote span context.
  ({SpanContext? parentSpanContext, APISpan? parentSpan}) _resolveParent(
    Context context,
  ) {
    final contextSpanContext = context.spanContext;
    final contextSpan = context.span;

    if (contextSpanContext != null &&
        contextSpanContext.isValid &&
        contextSpanContext.isRemote) {
      final contextSpanSc = contextSpan?.spanContext;
      final isSameSpan = contextSpanSc != null &&
          contextSpanSc.traceId == contextSpanContext.traceId &&
          contextSpanSc.spanId == contextSpanContext.spanId;
      return (
        parentSpanContext: contextSpanContext,
        parentSpan: isSameSpan ? contextSpan : null,
      );
    }

    if (contextSpan != null && contextSpan.spanContext.isValid) {
      return (
        parentSpanContext: contextSpan.spanContext,
        parentSpan: contextSpan,
      );
    }

    if (contextSpanContext != null && contextSpanContext.isValid) {
      return (parentSpanContext: contextSpanContext, parentSpan: null);
    }

    return (parentSpanContext: null, parentSpan: null);
  }

  SpanContext _buildSpanContext(SpanContext? parentSpanContext) {
    final factory = OTelFactory.otelFactory!;
    if (parentSpanContext == null) {
      return factory.spanContext(
        traceId: factory.traceId(),
        spanId: factory.spanId(),
        parentSpanId: factory.spanIdInvalid(),
      );
    }
    return factory.spanContext(
      traceId: parentSpanContext.traceId,
      spanId: factory.spanId(),
      parentSpanId: parentSpanContext.spanId,
      traceFlags: parentSpanContext.traceFlags,
      traceState: parentSpanContext.traceState,
    );
  }
}
