import 'dart:async';

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/tracing/embrace_tracer_provider.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:meta/meta.dart';

/// Embrace implementation of [APITracer].
///
/// Overrides [startSpan] and [createSpan] to forward span creation to the
/// native Embrace SDK via [EmbracePlatform]. All other tracing operations
/// (context management, span linking, etc.) delegate to a no-op [APITracer]
/// instance.
///
/// When [enabled] is false, both methods return a no-op span without calling
/// the platform.
@internal
class EmbraceTracer implements APITracer {
  /// Creates an [EmbraceTracer] backed by [provider].
  EmbraceTracer({required EmbraceTracerProvider provider})
      : _provider = provider,
        _delegate = TracerCreate.create(name: 'embrace');

  final EmbraceTracerProvider _provider;
  final APITracer _delegate;

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

    final effectiveParent =
        parentSpan ?? context?.span ?? Context.current.span;
    final parentSpanId = effectiveParent?.spanContext.spanId.toString();

    unawaited(
      EmbracePlatform.instance.startSpan(
        name,
        parentSpanId: parentSpanId,
        kind: kind.name,
      ),
    );

    return _delegate.startSpan(
      name,
      context: context,
      spanContext: spanContext,
      parentSpan: parentSpan,
      kind: kind,
      attributes: attributes,
      links: links,
      isRecording: isRecording,
    );
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

    final effectiveParent =
        parentSpan ?? context?.span ?? Context.current.span;
    final parentSpanId = effectiveParent?.spanContext.spanId.toString();

    unawaited(
      EmbracePlatform.instance.startSpan(
        name,
        parentSpanId: parentSpanId,
        startTimeMs: startTime?.millisecondsSinceEpoch,
        kind: kind.name,
      ),
    );

    return _delegate.createSpan(
      name: name,
      spanContext: spanContext,
      parentSpan: parentSpan,
      kind: kind,
      attributes: attributes,
      links: links,
      spanEvents: spanEvents,
      startTime: startTime,
      isRecording: isRecording,
      context: context,
    );
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
  T withSpan<T>(APISpan span, T Function() fn) =>
      _delegate.withSpan(span, fn);

  @override
  Future<T> withSpanAsync<T>(APISpan span, Future<T> Function() fn) =>
      _delegate.withSpanAsync(span, fn);
}
