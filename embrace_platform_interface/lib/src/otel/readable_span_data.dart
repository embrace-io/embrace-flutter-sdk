import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/src/otel/attributes_adapter.dart';
import 'package:embrace_platform_interface/src/otel/error_code_mapping.dart';
import 'package:embrace_platform_interface/src/otel/otel_id_utils.dart';
import 'package:embrace_platform_interface/src/otel/otel_span_adapter.dart';

/// Immutable snapshot of a completed span's data, suitable for export.
///
/// Two construction paths are supported:
/// - [ReadableSpanData.fromAdapter] — snapshots a just-ended [OTelSpanAdapter].
///   Attributes and events are empty because the native SDK owns them.
/// - [ReadableSpanData.fromRaw] — builds from raw primitive parameters, used
///   when replaying historical spans via `recordCompletedSpan`.
class ReadableSpanData {
  ReadableSpanData._({
    required this.name,
    required this.spanContext,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.attributes,
    required this.events,
    required this.resource,
  });

  /// Creates a [ReadableSpanData] from a completed [OTelSpanAdapter].
  ///
  /// The [adapter] must already be ended — i.e., [OTelSpanAdapter.endTime]
  /// must be non-null. Throws an [ArgumentError] if the adapter has not been
  /// ended yet.
  ///
  /// [resource] should be the result of `buildEmbraceResource(...)` (Ticket
  /// 1.4). Because the native SDK owns attribute and event state, [attributes]
  /// and [events] on the resulting [ReadableSpanData] will always be empty.
  factory ReadableSpanData.fromAdapter(
    OTelSpanAdapter adapter, {
    required Attributes resource,
  }) {
    final endTime = adapter.endTime;
    if (endTime == null) {
      throw ArgumentError(
        'ReadableSpanData.fromAdapter requires the adapter to be ended. '
        'Call adapter.end() before snapshotting.',
      );
    }
    return ReadableSpanData._(
      name: adapter.name,
      spanContext: adapter.spanContext,
      startTime: adapter.startTime,
      endTime: endTime,
      status: adapter.status,
      attributes: Attributes.of({}),
      events: const [],
      resource: resource,
    );
  }

  /// Creates a [ReadableSpanData] from raw primitive parameters.
  ///
  /// This path is used when replaying historical spans that were completed
  /// before or outside the live adapter lifecycle (e.g.,
  /// `recordCompletedSpan`).
  ///
  /// [spanId] and [traceId] must be valid W3C hex strings (16 and 32
  /// characters respectively). Malformed values produce an invalid
  /// [spanContext] ([SpanContext.isValid] == false).
  ///
  /// [startTimeMs] and [endTimeMs] are milliseconds since epoch.
  ///
  /// [errorCode] is converted to [SpanStatusCode] via [ErrorCodeMapping]:
  /// `null` → [SpanStatusCode.Ok], any non-null value → [SpanStatusCode.Error].
  ///
  /// [events] is a list of raw event maps, each with the keys:
  /// - `'name'` ([String]) — required
  /// - `'timestampMs'` ([int]?) — optional; defaults to [DateTime.now]
  /// - `'attributes'` ([Map<String, String>]?) — optional
  factory ReadableSpanData.fromRaw({
    required String name,
    required String spanId,
    required String traceId,
    required int startTimeMs,
    required int endTimeMs,
    ErrorCode? errorCode,
    Map<String, String>? attributes,
    List<Map<String, dynamic>>? events,
    required Attributes resource,
  }) {
    return ReadableSpanData._(
      name: name,
      spanContext: OtelIdUtils.buildSpanContext(spanId, traceId),
      startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMs),
      endTime: DateTime.fromMillisecondsSinceEpoch(endTimeMs),
      status: ErrorCodeMapping.toSpanStatus(errorCode),
      attributes: attributesFromMap(attributes),
      events: _convertRawEvents(events),
      resource: resource,
    );
  }

  /// The name of this span.
  final String name;

  /// The [SpanContext] identifying this span within its trace.
  final SpanContext spanContext;

  /// The time at which this span started.
  final DateTime startTime;

  /// The time at which this span ended.
  final DateTime endTime;

  /// The OTel status of this span.
  final SpanStatusCode status;

  /// The span's attributes.
  ///
  /// For spans created via [ReadableSpanData.fromAdapter], this is always empty
  /// because the native SDK owns attribute state. For spans created via
  /// [ReadableSpanData.fromRaw], this reflects the supplied attributes map.
  final Attributes attributes;

  /// The span's events.
  ///
  /// For spans created via [ReadableSpanData.fromAdapter], this is always empty
  /// because the native SDK owns event state. For spans created via
  /// [ReadableSpanData.fromRaw], this reflects the supplied raw event list.
  final List<SpanEvent> events;

  /// The OTel resource attributes for the Embrace SDK.
  ///
  /// Callers should supply the result of `buildEmbraceResource(...)`.
  final Attributes resource;

  static List<SpanEvent> _convertRawEvents(List<Map<String, dynamic>>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return List.unmodifiable(
      raw.map((e) {
        final eventName = e['name'] as String;
        final tsMs = e['timestampMs'] as int?;
        final eventAttrs = e['attributes'] as Map<String, String>?;
        final timestamp = tsMs != null
            ? DateTime.fromMillisecondsSinceEpoch(tsMs)
            : DateTime.now();
        return SpanEventCreate.create(
          name: eventName,
          timestamp: timestamp,
          attributes: eventAttrs != null ? attributesFromMap(eventAttrs) : null,
        );
      }),
    );
  }
}
