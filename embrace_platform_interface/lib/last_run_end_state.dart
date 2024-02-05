/// Used to represent the end state of the last run of the application.

enum LastRunEndState {
  //// The SDK has not been started yet, or it is not configured as the crash handler for the application
  invalid,

  /// The last run resulted in a crash
  crash,

  /// The last run did not result in a crash
  cleanExit
}
