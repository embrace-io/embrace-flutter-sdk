import 'dart:typed_data';

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Utility class for converting native W3C-compliant hex ID strings into
/// OTel value types.
class OtelIdUtils {
  OtelIdUtils._();

  /// Constructs an OTel [SpanContext] from the raw hex strings returned by the
  /// native SDK method channel.
  ///
  /// If [spanId] or [traceId] cannot be parsed as a valid hex string of the
  /// expected length, the corresponding field will be all-zeros and
  /// [SpanContext.isValid] will return false.
  ///
  /// The native SDK guarantees [traceId] is never null — it returns the
  /// all-zeros string when a trace ID is unavailable or invalid.
  static SpanContext buildSpanContext(String spanId, String traceId) {
    final spanIdBytes = tryParseHex(spanId, SpanId.spanIdLength);
    final traceIdBytes = tryParseHex(traceId, TraceId.traceIdLength);

    return SpanContextCreate.create(
      spanId: SpanIdCreate.create(
        spanIdBytes ?? Uint8List(SpanId.spanIdLength),
      ),
      traceId: TraceIdCreate.create(
        traceIdBytes ?? Uint8List(TraceId.traceIdLength),
      ),
      parentSpanId: SpanId.invalidSpanId,
      traceFlags: TraceFlags.sampled,
    );
  }

  /// Parses [hex] into a [Uint8List] of [expectedBytes] length.
  ///
  /// Returns null if [hex] is not exactly `expectedBytes * 2` hex characters
  /// or if any byte pair cannot be parsed.
  static Uint8List? tryParseHex(String hex, int expectedBytes) {
    if (hex.length != expectedBytes * 2) return null;
    try {
      final bytes = Uint8List(expectedBytes);
      for (var i = 0; i < expectedBytes; i++) {
        bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
