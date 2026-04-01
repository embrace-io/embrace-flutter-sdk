import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/logs/embrace_logger_provider.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:meta/meta.dart';

/// Embrace implementation of [APILogger].
///
/// Delegates [emit] to the native Embrace log methods by mapping the OTel
/// severity number to [EmbracePlatform.logInfo], [EmbracePlatform.logWarning],
/// or [EmbracePlatform.logError]. Attributes, timestamps, and event name are
/// accepted but not forwarded in v1.
@internal
class EmbraceLogger implements APILogger {
  /// Creates an [EmbraceLogger].
  EmbraceLogger({
    required this.name,
    required EmbraceLoggerProvider provider,
    this.version,
    this.schemaUrl,
    this.attributes,
  }) : _provider = provider;

  final EmbraceLoggerProvider _provider;

  @override
  final String name;

  @override
  final String? version;

  @override
  final String? schemaUrl;

  @override
  final Attributes? attributes;

  @override
  bool get enabled => _provider.enabled;

  @override
  void emit({
    DateTime? timeStamp,
    DateTime? observedTimestamp,
    Context? context,
    Severity? severityNumber,
    String? severityText,
    dynamic body,
    Attributes? attributes,
    String? eventName,
  }) {
    if (!enabled) return;

    final message = body?.toString() ?? '';
    final sev = severityNumber?.severityNumber ?? 0;

    if (sev >= 17) {
      EmbracePlatform.instance.logError(message, null);
    } else if (sev >= 13) {
      EmbracePlatform.instance.logWarning(message, null);
    } else {
      EmbracePlatform.instance.logInfo(message, null);
    }
  }
}
