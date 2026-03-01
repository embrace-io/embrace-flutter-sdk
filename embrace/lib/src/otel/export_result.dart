/// Result of an export or flush operation on a span exporter.
enum ExportResult {
  /// The operation completed successfully.
  success,

  /// The operation failed.
  failure,
}
