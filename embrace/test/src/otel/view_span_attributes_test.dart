import 'package:embrace/src/otel/view_span_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('viewSpanAttributes', () {
    test('sets screen.name to viewName', () {
      final attrs = viewSpanAttributes('HomeScreen', navigationActionPush);
      expect(attrs[screenName], equals('HomeScreen'));
    });

    test('sets navigation.action to action', () {
      final attrs = viewSpanAttributes('HomeScreen', navigationActionPush);
      expect(attrs[navigationAction], equals(navigationActionPush));
    });

    test('contains exactly two keys', () {
      final attrs = viewSpanAttributes('HomeScreen', navigationActionPop);
      expect(attrs.length, equals(2));
    });
  });
}
