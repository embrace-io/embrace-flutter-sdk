import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/tracing/embrace_tracer.dart';
import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:meta/meta.dart';

typedef _SpanExporterConfig = ({
  String endpoint,
  List<Map<String, String>>? headers,
  int? timeoutSeconds,
});

/// Embrace implementation of [APITracerProvider].
///
/// Holds a single [EmbraceTracer] instance returned by every [getTracer] call.
/// Registered via the Embrace OTel factory so that [OTelAPI.tracerProvider]
/// returns this provider after Embrace.start is called.
@internal
class EmbraceTracerProvider implements APITracerProvider {
  /// Creates an [EmbraceTracerProvider].
  EmbraceTracerProvider({
    required String endpoint,
    String serviceName = OTelAPI.defaultServiceName,
    String? serviceVersion = OTelAPI.defaultServiceVersion,
  })  : _endpoint = endpoint,
        _serviceName = serviceName,
        _serviceVersion = serviceVersion,
        _enabled = true,
        _isShutdown = false;

  late final EmbraceTracer _tracer = EmbraceTracer(provider: this);

  // endpoint, serviceName, and serviceVersion satisfy the APITracerProvider
  // interface but are not used by the Dart layer — the native Embrace SDK owns
  // these values and manages them independently.
  String _endpoint;
  String _serviceName;
  String? _serviceVersion;
  bool _enabled;
  bool _isShutdown;
  TimeProvider _timeProvider = defaultTimeProvider;

  final List<_SpanExporterConfig> _pendingSpanExporters = [];

  /// Returns the single [EmbraceTracer] instance regardless of [name],
  /// [version], [schemaUrl], or [attributes]. All instrumentation shares one
  /// tracer because span creation is delegated entirely to the native Embrace
  /// SDK, which does not distinguish between OTel instrumentation scopes.
  @override
  APITracer getTracer(
    String name, {
    String? version,
    String? schemaUrl,
    Attributes? attributes,
  }) =>
      _tracer;

  /// Adds an OTLP HTTP span exporter.
  ///
  /// If the Embrace SDK has already started, the exporter is configured on the
  /// native SDK immediately. Otherwise the config is queued and forwarded once
  /// [flushPendingExporters] is called after the SDK starts.
  void addSpanExporter({
    required String endpoint,
    List<Map<String, String>>? headers,
    int? timeoutSeconds,
  }) {
    if (EmbracePlatform.instance.isStarted) {
      EmbracePlatform.instance.addSpanExporter(
        endpoint: endpoint,
        headers: headers,
        timeoutSeconds: timeoutSeconds,
      );
    } else {
      _pendingSpanExporters.add(
        (endpoint: endpoint, headers: headers, timeoutSeconds: timeoutSeconds),
      );
    }
  }

  /// Forwards all queued span exporter configs to the native SDK.
  ///
  /// Called by `Embrace._start` after [EmbracePlatform.attachToHostSdk].
  void flushPendingExporters() {
    for (final config in List.of(_pendingSpanExporters)) {
      EmbracePlatform.instance.addSpanExporter(
        endpoint: config.endpoint,
        headers: config.headers,
        timeoutSeconds: config.timeoutSeconds,
      );
    }
    _pendingSpanExporters.clear();
  }

  /// Clears the pending exporter queue. For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _pendingSpanExporters.clear();
  }

  @override
  Future<bool> shutdown() async {
    _isShutdown = true;
    _enabled = false;
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
  TimeProvider get timeProvider => _timeProvider;

  @override
  set timeProvider(TimeProvider value) => _timeProvider = value;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  @override
  bool get isShutdown => _isShutdown;

  @override
  set isShutdown(bool value) => _isShutdown = value;
}
