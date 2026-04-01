import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/logs/embrace_logger.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:meta/meta.dart';

typedef _LogExporterConfig = ({
  String endpoint,
  List<Map<String, String>>? headers,
  int? timeoutSeconds,
});

/// Embrace implementation of [APILoggerProvider].
///
/// Delegates [getLogger] to the OTel API no-op implementation. The primary
/// purpose of this class is to manage OTLP HTTP log record exporter
/// configuration: calls may be queued before [EmbracePlatform.attachToHostSdk]
/// and forwarded to the native SDK once [flushPendingExporters] is called.
@internal
class EmbraceLoggerProvider implements APILoggerProvider {
  /// Creates an [EmbraceLoggerProvider].
  EmbraceLoggerProvider({
    required String endpoint,
    String serviceName = OTelAPI.defaultServiceName,
    String? serviceVersion = OTelAPI.defaultServiceVersion,
  })  : _endpoint = endpoint,
        _serviceName = serviceName,
        _serviceVersion = serviceVersion,
        _enabled = true,
        _isShutdown = false;

  String _endpoint;
  String _serviceName;
  String? _serviceVersion;
  bool _enabled;
  bool _isShutdown;

  final List<_LogExporterConfig> _pendingLogExporters = [];
  final Map<String, EmbraceLogger> _loggerCache = {};

  /// Adds an OTLP HTTP log record exporter.
  ///
  /// If the Embrace SDK has already started, the exporter is configured on the
  /// native SDK immediately. Otherwise the config is queued and forwarded once
  /// [flushPendingExporters] is called after the SDK starts.
  void addLogRecordExporter({
    required String endpoint,
    List<Map<String, String>>? headers,
    int? timeoutSeconds,
  }) {
    if (EmbracePlatform.instance.isStarted) {
      EmbracePlatform.instance.addLogRecordExporter(
        endpoint: endpoint,
        headers: headers,
        timeoutSeconds: timeoutSeconds,
      );
    } else {
      _pendingLogExporters.add(
        (endpoint: endpoint, headers: headers, timeoutSeconds: timeoutSeconds),
      );
    }
  }

  /// Forwards all queued log record exporter configs to the native SDK.
  ///
  /// Called by `Embrace._start` after [EmbracePlatform.attachToHostSdk].
  void flushPendingExporters() {
    for (final config in List.of(_pendingLogExporters)) {
      EmbracePlatform.instance.addLogRecordExporter(
        endpoint: config.endpoint,
        headers: config.headers,
        timeoutSeconds: config.timeoutSeconds,
      );
    }
    _pendingLogExporters.clear();
  }

  /// Clears the pending exporter queue. For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _pendingLogExporters.clear();
  }

  // ── APILoggerProvider interface ──────────────────────────────────────────

  @override
  EmbraceLogger getLogger(
    String name, {
    String? version,
    String? schemaUrl,
    Attributes? attributes,
  }) {
    final key = '$name:$version';
    return _loggerCache.putIfAbsent(
      key,
      () => EmbraceLogger(
        name: name,
        provider: this,
        version: version,
        schemaUrl: schemaUrl,
        attributes: attributes,
      ),
    );
  }

  @override
  Future<bool> shutdown() async {
    _isShutdown = true;
    _enabled = false;
    _loggerCache.clear();
    return true;
  }

  @override
  String get endpoint => _endpoint;

  @override
  set endpoint(String value) => _endpoint = value;

  @override
  String get serviceName => _serviceName;

  @override
  set serviceName(String value) => _serviceName = value;

  @override
  String? get serviceVersion => _serviceVersion;

  @override
  set serviceVersion(String? value) => _serviceVersion = value;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  @override
  bool get isShutdown => _isShutdown;

  @override
  set isShutdown(bool value) => _isShutdown = value;
}
