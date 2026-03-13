/// OTel severity mapping for Embrace log methods.
///
/// Covers the five Embrace logging cases and their OTel severity numbers per
/// the OTel Log Data Model spec (https://opentelemetry.io/docs/specs/otel/logs/data-model/).
enum EmbraceSeverity {
  /// Corresponds to `Severity.info` / `logInfo`.
  info,

  /// Corresponds to `Severity.warning` / `logWarning`.
  warning,

  /// Corresponds to `Severity.error` / `logError`.
  error,

  /// Corresponds to `logDartError` with `wasHandled: false`.
  dartError,

  /// Corresponds to `logHandledDartError` — `logDartError` with
  /// `wasHandled: true`.
  handledDartError,
}

/// Maps [EmbraceSeverity] values to OTel severity numbers.
///
/// Severity numbers follow the OTel Log Data Model:
/// - INFO  = 9
/// - WARN  = 13
/// - ERROR = 17
/// - FATAL = 21
///
/// | [EmbraceSeverity]                   | OTel level | number |
/// |-------------------------------------|------------|--------|
/// | [EmbraceSeverity.info]              | INFO       | 9      |
/// | [EmbraceSeverity.warning]           | WARN       | 13     |
/// | [EmbraceSeverity.error]             | ERROR      | 17     |
/// | [EmbraceSeverity.handledDartError]  | ERROR      | 17     |
/// | [EmbraceSeverity.dartError]         | FATAL      | 21     |
abstract final class SeverityMapping {
  /// Returns the OTel severity number for the given [EmbraceSeverity].
  static int toSeverityNumber(EmbraceSeverity severity) => switch (severity) {
        EmbraceSeverity.info => 9,
        EmbraceSeverity.warning => 13,
        EmbraceSeverity.error => 17,
        EmbraceSeverity.handledDartError => 17,
        EmbraceSeverity.dartError => 21,
      };

  /// Maps a log method name to an [EmbraceSeverity].
  ///
  /// The method name strings (`'logInfo'`, `'logError'`, etc.) are the OTel/
  /// method-channel method names and are intentionally decoupled from Dart
  /// symbol names so that Dart refactoring does not silently change the
  /// channel protocol.
  ///
  /// Recognised names:
  /// - `'logInfo'` → [EmbraceSeverity.info]
  /// - `'logWarning'` → [EmbraceSeverity.warning]
  /// - `'logError'` → [EmbraceSeverity.error]
  /// - `'logDartError'` → [EmbraceSeverity.dartError]
  /// - `'logHandledDartError'` → [EmbraceSeverity.handledDartError]
  ///
  /// Returns `null` for unrecognised names.
  static EmbraceSeverity? fromLogMethodName(String methodName) =>
      switch (methodName) {
        'logInfo' => EmbraceSeverity.info,
        'logWarning' => EmbraceSeverity.warning,
        'logError' => EmbraceSeverity.error,
        'logDartError' => EmbraceSeverity.dartError,
        'logHandledDartError' => EmbraceSeverity.handledDartError,
        _ => null,
      };
}
