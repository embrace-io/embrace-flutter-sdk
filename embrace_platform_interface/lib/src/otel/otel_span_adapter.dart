import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/src/otel/otel_id_utils.dart';

/// Adapts an [EmbraceSpanDelegate] to an OTel-compatible span interface.
///
/// Since [EmbraceSpanDelegate.traceId] is asynchronous but OTel
/// [SpanContext.traceId] must be synchronous, construction is asynchronous.
/// Use the [create] factory to instantiate.
///
/// If the native trace ID cannot be parsed as a valid 32-character hex string,
/// [SpanContext.isValid] will be false (the trace ID bytes will be all zeros).
class OTelSpanAdapter {
  OTelSpanAdapter._({
    required String name,
    required EmbraceSpanDelegate embraceSpan,
    required SpanContext spanContext,
    required DateTime startTime,
  })  : _name = name,
        _embraceSpan = embraceSpan,
        _spanContext = spanContext,
        _startTime = startTime;

  final String _name;
  final EmbraceSpanDelegate _embraceSpan;
  final SpanContext _spanContext;
  final DateTime _startTime;

  bool _isEnded = false;
  DateTime? _endTime;
  ErrorCode? _errorCode;

  /// Creates an [OTelSpanAdapter] by awaiting the native trace ID from
  /// [EmbraceSpanDelegate.traceId] so that [SpanContext] can be built
  /// synchronously.
  static Future<OTelSpanAdapter> create(
    String name,
    EmbraceSpanDelegate embraceSpan,
  ) async {
    final rawTraceId = await embraceSpan.traceId;
    final spanContext =
        OtelIdUtils.buildSpanContext(embraceSpan.id, rawTraceId);
    return OTelSpanAdapter._(
      name: name,
      embraceSpan: embraceSpan,
      spanContext: spanContext,
      startTime: DateTime.now(),
    );
  }

  /// The name of this span.
  String get name => _name;

  /// The [SpanContext] for this span, built from the native span and trace IDs.
  SpanContext get spanContext => _spanContext;

  /// Whether this span is still recording (i.e. has not been ended).
  bool get isRecording => !_isEnded;

  /// The OTel [SpanStatusCode] for this span.
  ///
  /// Returns [SpanStatusCode.Unset] while recording.
  /// Returns [SpanStatusCode.Ok] after [end] with no [ErrorCode].
  /// Returns [SpanStatusCode.Error] after [end] with any [ErrorCode].
  SpanStatusCode get status {
    if (!_isEnded) return SpanStatusCode.Unset;
    return _spanStatusFromErrorCode(_errorCode);
  }

  /// The start time of this span.
  DateTime get startTime => _startTime;

  /// The end time of this span, or null if not yet ended.
  DateTime? get endTime => _endTime;

  /// The underlying [EmbraceSpanDelegate].
  EmbraceSpanDelegate get embraceSpan => _embraceSpan;

  /// Sets a string attribute on the span by delegating to
  /// [EmbraceSpanDelegate.addAttribute].
  Future<bool> setStringAttribute(String key, String value) =>
      _embraceSpan.addAttribute(key, value);

  /// Adds an event to the span by delegating to [EmbraceSpanDelegate.addEvent].
  Future<bool> addEmbraceEvent(
    String name, {
    int? timestampMs,
    Map<String, String>? attributes,
  }) =>
      _embraceSpan.addEvent(
        name,
        timestampMs: timestampMs,
        attributes: attributes,
      );

  /// Ends this span by delegating to [EmbraceSpanDelegate.stop].
  ///
  /// After this call, [isRecording] returns false and [status] reflects
  /// the supplied [errorCode]. Returns false if already ended.
  Future<bool> end({ErrorCode? errorCode, int? endTimeMs}) async {
    if (_isEnded) return false;
    _errorCode = errorCode;
    _isEnded = true;
    _endTime = endTimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(endTimeMs)
        : DateTime.now();
    return _embraceSpan.stop(errorCode: errorCode, endTimeMs: endTimeMs);
  }

  static SpanStatusCode _spanStatusFromErrorCode(ErrorCode? errorCode) {
    if (errorCode == null) return SpanStatusCode.Ok;
    return SpanStatusCode.Error;
  }
}
