import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Converts a [Map<String, String>] to an OTel [Attributes] object.
///
/// Returns empty [Attributes] if [map] is null or empty.
/// Empty string values are silently dropped — OTel [Attributes] does not
/// permit empty string values.
Attributes attributesFromMap(Map<String, String>? map) {
  if (map == null || map.isEmpty) {
    return Attributes.of({});
  }
  return Attributes.of(map);
}

/// Converts an OTel [Attributes] object to a [Map<String, String>].
///
/// Returns an empty map if [attributes] is null or empty.
/// Non-string attribute values (bool, int, double, List) are converted
/// to strings via [Object.toString] — this conversion is intentionally lossy.
Map<String, String> mapFromAttributes(Attributes? attributes) {
  if (attributes == null || attributes.isEmpty) {
    return {};
  }
  return {
    for (final entry in attributes.toMap().entries)
      entry.key: entry.value.value.toString(),
  };
}
