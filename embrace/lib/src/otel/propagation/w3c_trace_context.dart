import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/context/otel_context_utils.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';

/// Helpers for W3C Trace Context header injection and extraction.
///
/// See https://www.w3.org/TR/trace-context/
class W3cTraceContext {
  W3cTraceContext._();

  static const String _headerName = 'traceparent';
  static const String _version = '00';

  /// Builds a W3C `traceparent` header value from [spanContext].
  ///
  /// Returns `null` if [spanContext] is invalid (zero trace-id or span-id).
  static String? fromSpanContext(SpanContext spanContext) {
    if (!spanContext.isValid) return null;
    final flags =
        spanContext.traceFlags.asByte.toRadixString(16).padLeft(2, '0');
    final traceId = spanContext.traceId.hexString;
    final spanId = spanContext.spanId.hexString;
    return '$_version-$traceId-$spanId-$flags';
  }

  /// Parses a W3C `traceparent` header value into a [SpanContext].
  ///
  /// Returns `null` if [header] is null, has the wrong number of segments,
  /// invalid field lengths, or non-hex characters. The version field is
  /// ignored.
  static SpanContext? extract(String? header) {
    if (header == null) return null;
    final parts = header.split('-');
    if (parts.length != 4) return null;
    final traceIdHex = parts[1];
    final spanIdHex = parts[2];
    final flagsHex = parts[3];
    if (traceIdHex.length != 32) return null;
    if (spanIdHex.length != 16) return null;
    if (flagsHex.length != 2) return null;
    final flagByte = int.tryParse(flagsHex, radix: 16);
    if (flagByte == null) return null;
    try {
      final traceId = OTelAPI.traceIdFrom(traceIdHex);
      final spanId = OTelAPI.spanIdFrom(spanIdHex);
      if (!traceId.isValid || !spanId.isValid) return null;
      return OTelAPI.spanContext(
        traceId: traceId,
        spanId: spanId,
        traceFlags: OTelAPI.traceFlags(flagByte),
        isRemote: true,
      );
    } on FormatException {
      return null;
    }
  }

  /// Injects the current span's `traceparent` header into [headers].
  ///
  /// Delegates to [EmbracePlatform.generateW3cTraceparent]; falls back to
  /// Dart construction if the platform returns null.
  ///
  /// Does nothing when no span is active.
  static Future<void> injectCurrent(Map<String, String> headers) async {
    final spanContext = OTelContextUtils.currentSpanContext();
    if (spanContext == null || !spanContext.isValid) return;
    final traceIdHex = spanContext.traceId.hexString;
    final spanIdHex = spanContext.spanId.hexString;
    var value = await EmbracePlatform.instance
        .generateW3cTraceparent(traceIdHex, spanIdHex);
    value ??= fromSpanContext(spanContext);
    if (value != null) {
      headers[_headerName] = value;
    }
  }

  /// Injects the current span's `traceparent` header into [headers] without
  /// calling the platform.
  ///
  /// Does nothing when no span is active.
  static void injectCurrentSync(Map<String, dynamic> headers) {
    final spanContext = OTelContextUtils.currentSpanContext();
    if (spanContext == null || !spanContext.isValid) return;
    final value = fromSpanContext(spanContext);
    if (value != null) {
      headers[_headerName] = value;
    }
  }
}
