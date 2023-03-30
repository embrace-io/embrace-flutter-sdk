import 'dart:async';

/// Returns the messages that were printed in the console
/// while the action was running
///
/// To achieve this, it wraps the action in a custom zone where the print
/// method is overriden
List<String> getPrints(void Function() action) {
  final printed = <String>[];
  runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => printed.add(line),
    ),
  );
  return printed;
}
