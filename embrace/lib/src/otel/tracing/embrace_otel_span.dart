import 'dart:async';

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart'
    as otel;
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:meta/meta.dart';

/// Embrace implementation of [otel.APISpan].
///
/// Holds the IDs needed to route platform-channel calls. All span state
/// lives in the native Embrace SDK. Each mutating method forwards to the
/// appropriate [EmbracePlatform] method using the native [_nativeSpanId].
///
/// [_nativeSpanId] is a [Future] because [EmbracePlatform.startSpan] is
/// asynchronous. All platform calls are queued via [_withSpanId] and execute
/// once the ID resolves.
@internal
class EmbraceOTelSpan implements otel.APISpan {
  /// Creates an [EmbraceOTelSpan].
  ///
  /// [nativeSpanId] is the [Future] returned by [EmbracePlatform.startSpan].
  /// [previousContext] is the [otel.Context] that was active before this span
  /// was made current; [end] restores it. Pass `null` for spans created via
  /// [otel.APITracer.createSpan] that are never attached to context.
  EmbraceOTelSpan({
    required String name,
    required Future<String?> nativeSpanId,
    required otel.SpanContext spanContext,
    required otel.InstrumentationScope instrumentationScope,
    otel.Context? previousContext,
    otel.APISpan? parentSpan,
    otel.SpanKind kind = otel.SpanKind.internal,
    DateTime? startTime,
  })  : _name = name,
        _nativeSpanId = nativeSpanId,
        _spanContext = spanContext,
        _instrumentationScope = instrumentationScope,
        _previousContext = previousContext,
        _parentSpan = parentSpan,
        _kind = kind,
        _startTime = startTime ?? DateTime.now();

  String _name;
  final Future<String?> _nativeSpanId;
  final otel.SpanContext _spanContext;
  final otel.InstrumentationScope _instrumentationScope;
  final otel.Context? _previousContext;
  final otel.APISpan? _parentSpan;
  final otel.SpanKind _kind;
  final DateTime _startTime;
  DateTime? _endTime;
  bool _isEnded = false;
  otel.SpanStatusCode _status = otel.SpanStatusCode.Unset;
  String? _statusDescription;

  // ── Getters ────────────────────────────────────────────────────────────────

  @override
  String get name => _name;

  @override
  otel.SpanId get spanId => _spanContext.spanId;

  @override
  otel.InstrumentationScope get instrumentationScope => _instrumentationScope;

  @override
  DateTime get startTime => _startTime;

  @override
  DateTime? get endTime => _endTime;

  @override
  bool get isEnded => _isEnded;

  @override
  otel.SpanStatusCode get status => _status;

  @override
  String? get statusDescription => _statusDescription;

  @override
  otel.SpanContext get spanContext => _spanContext;

  @override
  bool get isValid => _spanContext.isValid;

  @override
  otel.APISpan? get parentSpan => _parentSpan;

  @override
  otel.SpanContext? get parentSpanContext => _parentSpan?.spanContext;

  @override
  otel.SpanKind get kind => _kind;

  /// Returns an empty unmodifiable list — span events are owned by the native SDK.
  @override
  List<otel.SpanEvent>? get spanEvents => const [];

  /// Returns an empty unmodifiable list — span links are owned by the native SDK.
  @override
  List<otel.SpanLink>? get spanLinks => const [];

  @override
  bool get isRecording => !_isEnded;

  /// Always returns an empty [otel.Attributes] — attributes are owned by the
  /// native SDK and are not readable from the Dart layer.
  @override
  @visibleForTesting
  otel.Attributes get attributes => otel.Attributes.of({});

  /// No-op — attributes are owned by the native SDK.
  @override
  set attributes(otel.Attributes newAttributes) {}

  // ── Attribute setters ──────────────────────────────────────────────────────

  @override
  void setStringAttribute<T>(String name, String value) =>
      _setAttribute(name, value);

  @override
  void setBoolAttribute(String name, bool value) =>
      _setAttribute(name, value.toString());

  @override
  void setIntAttribute(String name, int value) =>
      _setAttribute(name, value.toString());

  @override
  void setDoubleAttribute(String name, double value) =>
      _setAttribute(name, value.toString());

  @override
  void setDateTimeAsStringAttribute(String name, DateTime value) =>
      _setAttribute(name, otel.Timestamp.dateTimeToString(value));

  @override
  void setStringListAttribute<T>(String name, List<String> value) =>
      _setAttribute(name, value.toString());

  @override
  void setBoolListAttribute(String name, List<bool> value) =>
      _setAttribute(name, value.toString());

  @override
  void setIntListAttribute(String name, List<int> value) =>
      _setAttribute(name, value.toString());

  @override
  void setDoubleListAttribute(String name, List<double> value) =>
      _setAttribute(name, value.toString());

  @override
  void addAttributes(otel.Attributes attrs) {
    for (final attr in attrs.toList()) {
      _setAttribute(attr.key, attr.value.toString());
    }
  }

  void _setAttribute(String name, String value) {
    if (_isEnded) return;
    unawaited(
      _withSpanId(
        (id) => EmbracePlatform.instance.addSpanAttribute(id, name, value),
      ),
    );
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  @override
  void addEvent(otel.SpanEvent spanEvent) {
    if (_isEnded) return;
    unawaited(
      _withSpanId(
        (id) => EmbracePlatform.instance.addSpanEvent(
          id,
          spanEvent.name,
          timestampMs: spanEvent.timestamp.millisecondsSinceEpoch,
          attributes: _attrsToMap(spanEvent.attributes),
        ),
      ),
    );
  }

  @override
  void addEventNow(String name, [otel.Attributes? attributes]) {
    if (_isEnded) return;
    unawaited(
      _withSpanId(
        (id) => EmbracePlatform.instance.addSpanEvent(
          id,
          name,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          attributes: _attrsToMap(attributes),
        ),
      ),
    );
  }

  @override
  void addEvents(Map<String, otel.Attributes?> events) {
    events.forEach(addEventNow);
  }

  // ── Links ──────────────────────────────────────────────────────────────────

  @override
  void addLink(otel.SpanContext linkedContext, [otel.Attributes? attributes]) {
    if (_isEnded) return;
    final attrs = _attrsToMap(attributes) ?? {};
    unawaited(
      _withSpanId(
        (id) => EmbracePlatform.instance.addSpanLink(
          id,
          linkedContext.traceId.toString(),
          linkedContext.spanId.toString(),
          attrs,
        ),
      ),
    );
  }

  @override
  void addSpanLink(otel.SpanLink spanLink) {
    addLink(spanLink.spanContext, spanLink.attributes);
  }

  // ── Status / name ──────────────────────────────────────────────────────────

  @override
  void setStatus(otel.SpanStatusCode statusCode, [String? description]) {
    if (_isEnded || statusCode == otel.SpanStatusCode.Unset) return;
    if (statusCode == otel.SpanStatusCode.Ok) {
      _status = statusCode;
      _statusDescription = null;
    } else if (_status != otel.SpanStatusCode.Ok) {
      _status = statusCode;
      if (description != null && description.isNotEmpty) {
        _statusDescription = description;
      }
    } else {
      // Current status is Ok; Error cannot downgrade Ok — skip platform call.
      return;
    }
    unawaited(
      _withSpanId(
        (id) => EmbracePlatform.instance.setSpanStatus(
          id,
          _toPlatformStatus(statusCode),
          description: description,
        ),
      ),
    );
  }

  @override
  void updateName(String name) {
    if (_isEnded) return;
    _name = name;
    unawaited(
      _withSpanId((id) => EmbracePlatform.instance.updateSpanName(id, name)),
    );
  }

  // ── Exception ──────────────────────────────────────────────────────────────

  @override
  void recordException(
    Object exception, {
    StackTrace? stackTrace,
    otel.Attributes? attributes,
    bool? escaped,
  }) {
    if (_isEnded) return;
    final attrs = <String, String>{
      'exception.type': exception.runtimeType.toString(),
      'exception.message': exception.toString(),
    };
    if (stackTrace != null) {
      attrs['exception.stacktrace'] = stackTrace.toString();
    }
    if (escaped != null) attrs['exception.escaped'] = escaped.toString();
    if (attributes != null) {
      final extra = _attrsToMap(attributes);
      if (extra != null) attrs.addAll(extra);
    }
    unawaited(
      _withSpanId(
        (id) => EmbracePlatform.instance.addSpanEvent(
          id,
          'exception',
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          attributes: attrs,
        ),
      ),
    );
  }

  // ── End ────────────────────────────────────────────────────────────────────

  @override
  void end({DateTime? endTime, otel.SpanStatusCode? spanStatus}) {
    if (_isEnded) return;
    _endTime = endTime ?? DateTime.now();
    if (spanStatus != null) setStatus(spanStatus);
    _isEnded = true;
    unawaited(
      _withSpanId(
        (id) => EmbracePlatform.instance.stopSpan(
          id,
          endTimeMs: _endTime!.millisecondsSinceEpoch,
        ),
      ),
    );
    if (_previousContext != null) otel.Context.current = _previousContext!;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _withSpanId(Future<void> Function(String id) action) async {
    final id = await _nativeSpanId;
    if (id == null) return;
    await action(id);
  }

  static SpanStatusCode _toPlatformStatus(otel.SpanStatusCode code) =>
      switch (code) {
        otel.SpanStatusCode.Ok => SpanStatusCode.ok,
        otel.SpanStatusCode.Error => SpanStatusCode.error,
        otel.SpanStatusCode.Unset => SpanStatusCode.unset,
      };

  static Map<String, String>? _attrsToMap(otel.Attributes? attrs) {
    if (attrs == null || attrs.isEmpty) return null;
    return {for (final a in attrs.toList()) a.key: a.value.toString()};
  }
}
