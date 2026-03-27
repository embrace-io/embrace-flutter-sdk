import 'dart:async';

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
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
        _delegate = TracerCreate.create(name: 'embrace'),
        _instrumentationScope =
            InstrumentationScopeCreate.create(name: 'embrace');

  final EmbraceTracerProvider _provider;
  final APITracer _delegate;
  final InstrumentationScope _instrumentationScope;

  @override
  bool get enabled => _provider.enabled && !_provider.isShutdown;

  @override
  APISpan startSpan(
    String name, {
    Context? context,
    SpanContext? spanContext,
    APISpan? parentSpan,
    SpanKind kind = SpanKind.internal,
    Attributes? attributes,
    List<SpanLink>? links,
    bool? isRecording = true,
  }) {
    if (!enabled) {
      return _delegate.startSpan(
        name,
        context: context,
        spanContext: spanContext,
        parentSpan: parentSpan,
        kind: kind,
        attributes: attributes,
        links: links,
        isRecording: false,
      );
    }

    final previousContext = Context.current;
    final effectiveContext = context ?? Context.current;
    final otelSpanContext = _buildSpanContext(
      parentSpan: parentSpan,
      context: effectiveContext,
      spanContext: spanContext,
    );

    final nativeSpanId = EmbracePlatform.instance.startSpan(
      name,
      parentSpanId:
          _resolveParentSpanId(parentSpan: parentSpan, context: context),
    );

    final span = EmbraceOTelSpan(
      name: name,
      nativeSpanId: nativeSpanId,
      spanContext: otelSpanContext,
      instrumentationScope: _instrumentationScope,
      previousContext: previousContext,
      parentSpan: parentSpan,
      kind: kind,
    );

    if (attributes != null) span.addAttributes(attributes);
    links?.forEach(span.addSpanLink);

    Context.current = effectiveContext.setCurrentSpan(span);
    return span;
  }

  @override
  APISpan createSpan({
    required String name,
    SpanContext? spanContext,
    APISpan? parentSpan,
    SpanKind kind = SpanKind.internal,
    Attributes? attributes,
    List<SpanLink>? links,
    List<SpanEvent>? spanEvents,
    DateTime? startTime,
    bool? isRecording,
    Context? context,
  }) {
    if (!enabled) {
      return _delegate.createSpan(
        name: name,
        spanContext: spanContext,
        parentSpan: parentSpan,
        kind: kind,
        attributes: attributes,
        links: links,
        spanEvents: spanEvents,
        startTime: startTime,
        isRecording: false,
        context: context,
      );
    }

    final effectiveContext = context ?? Context.current;
    final otelSpanContext = _buildSpanContext(
      parentSpan: parentSpan,
      context: effectiveContext,
      spanContext: spanContext,
    );

    final nativeSpanId = EmbracePlatform.instance.startSpan(
      name,
      parentSpanId:
          _resolveParentSpanId(parentSpan: parentSpan, context: context),
      startTimeMs: startTime?.millisecondsSinceEpoch,
    );

    final span = EmbraceOTelSpan(
      name: name,
      nativeSpanId: nativeSpanId,
      spanContext: otelSpanContext,
      instrumentationScope: _instrumentationScope,
      parentSpan: parentSpan,
      kind: kind,
      startTime: startTime,
    );

    if (attributes != null) span.addAttributes(attributes);
    links?.forEach(span.addSpanLink);
    spanEvents?.forEach(span.addEvent);

    return span;
  }

  @override
  String get name => _delegate.name;

  @override
  String? get version => _delegate.version;

  @override
  String? get schemaUrl => _delegate.schemaUrl;

  @override
  Attributes? get attributes => _delegate.attributes;

  @override
  set attributes(Attributes? value) => _delegate.attributes = value;

  @override
  APISpan? get currentSpan => _delegate.currentSpan;

  @override
  T withSpan<T>(APISpan span, T Function() fn) => _delegate.withSpan(span, fn);

  @override
  Future<T> withSpanAsync<T>(APISpan span, Future<T> Function() fn) =>
      _delegate.withSpanAsync(span, fn);

  SpanContext _buildSpanContext({
    APISpan? parentSpan,
    Context? context,
    SpanContext? spanContext,
  }) {
    if (spanContext != null && spanContext.isValid) return spanContext;

    final effectiveContext = context ?? Context.current;
    final effectiveParent = parentSpan ?? effectiveContext.span;

    if (effectiveParent != null) {
      return OTelFactory.otelFactory!.spanContext(
        traceId: effectiveParent.spanContext.traceId,
        spanId: OTelFactory.otelFactory!.spanId(),
        parentSpanId: effectiveParent.spanContext.spanId,
        traceFlags: effectiveParent.spanContext.traceFlags,
        traceState: effectiveParent.spanContext.traceState,
      );
    }

    return OTelFactory.otelFactory!.spanContext(
      traceId: OTelFactory.otelFactory!.traceId(),
      spanId: OTelFactory.otelFactory!.spanId(),
      parentSpanId: OTelFactory.otelFactory!.spanIdInvalid(),
    );
  }

  String? _resolveParentSpanId({APISpan? parentSpan, Context? context}) {
    final effectiveParent = parentSpan ?? context?.span ?? Context.current.span;
    return effectiveParent?.spanContext.spanId.toString();
  }
}
