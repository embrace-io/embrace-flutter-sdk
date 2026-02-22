import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:embrace_platform_interface/src/otel/attributes_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('attributesFromMap', () {
    test('returns empty Attributes for null map', () {
      final result = attributesFromMap(null);
      expect(result.isEmpty, isTrue);
    });

    test('returns empty Attributes for empty map', () {
      final result = attributesFromMap({});
      expect(result.isEmpty, isTrue);
    });

    test('converts single entry map correctly', () {
      final result = attributesFromMap({'key': 'value'});
      expect(result.getString('key'), 'value');
    });

    test('converts multi-entry map correctly', () {
      final result = attributesFromMap({
        'alpha': 'one',
        'beta': 'two',
        'gamma': 'three',
      });
      expect(result.getString('alpha'), 'one');
      expect(result.getString('beta'), 'two');
      expect(result.getString('gamma'), 'three');
    });

    test('silently drops empty string values', () {
      final result = attributesFromMap({'empty': '', 'present': 'value'});
      expect(result.getString('empty'), isNull);
      expect(result.getString('present'), 'value');
    });
  });

  group('mapFromAttributes', () {
    test('returns empty map for null Attributes', () {
      expect(mapFromAttributes(null), isEmpty);
    });

    test('returns empty map for empty Attributes', () {
      final empty = Attributes.of({});
      expect(mapFromAttributes(empty), isEmpty);
    });

    test('converts string attributes correctly', () {
      final attrs = Attributes.of({'key': 'value'});
      expect(mapFromAttributes(attrs), {'key': 'value'});
    });

    test('converts int attribute to string', () {
      final attrs = Attributes.of({'count': 42});
      expect(mapFromAttributes(attrs), {'count': '42'});
    });

    test('converts bool attribute to string', () {
      final attrs = Attributes.of({'flag': true});
      expect(mapFromAttributes(attrs), {'flag': 'true'});
    });

    test('converts double attribute to string', () {
      final attrs = Attributes.of({'ratio': 3.14});
      expect(mapFromAttributes(attrs), {'ratio': '3.14'});
    });
  });

  group('round-trip conversion', () {
    test('Map -> Attributes -> Map preserves all string entries', () {
      const original = {
        'service': 'checkout',
        'version': '1.0',
        'region': 'us-east-1',
      };
      final roundTripped = mapFromAttributes(attributesFromMap(original));
      expect(roundTripped, original);
    });

    test('empty map survives round-trip', () {
      final result = mapFromAttributes(attributesFromMap({}));
      expect(result, isEmpty);
    });

    test('null map survives round-trip', () {
      final result = mapFromAttributes(attributesFromMap(null));
      expect(result, isEmpty);
    });
  });
}
