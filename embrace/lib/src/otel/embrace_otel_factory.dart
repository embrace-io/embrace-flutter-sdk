import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace/src/otel/tracing/embrace_tracer_provider.dart';
import 'package:meta/meta.dart';

/// Embrace implementation of [OTelFactory].
///
/// Registered via `OTelAPI.initialize` when `Embrace.start` is called so that
/// all `OTelAPI` calls are automatically backed by the Embrace SDK.
///
/// Extends [OTelAPIFactory] to inherit all construction methods (attributes,
/// span/trace IDs, context, etc.) as API no-ops.
@internal
class EmbraceOTelFactory extends OTelAPIFactory {
  /// Creates an [EmbraceOTelFactory].
  ///
  /// The constructor signature matches [OTelFactoryCreationFunction] so that
  /// `EmbraceOTelFactory.new` can be passed as the tearoff.
  EmbraceOTelFactory({
    required super.apiEndpoint,
    required super.apiServiceName,
    required super.apiServiceVersion,
  }) : super(factoryFactory: EmbraceOTelFactory.new);

  @override
  APITracerProvider tracerProvider({
    required String endpoint,
    String serviceName = OTelAPI.defaultServiceName,
    String? serviceVersion = OTelAPI.defaultServiceVersion,
  }) {
    return EmbraceTracerProvider(
      endpoint: endpoint,
      serviceName: serviceName,
      serviceVersion: serviceVersion,
    );
  }
}
