/// Defines how long a user session property is retained
enum PropertyScope {
  /// Cleared when the current user session ends
  userSession,

  /// Cleared when the app process terminates
  process,

  /// Persists across app launches until explicitly removed
  permanent
}
