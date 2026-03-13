/// Returns OTel semantic convention attributes for a view/navigation span.
///
/// - [viewName]: the name of the view/screen; used for [screenName]
/// - [action]: the navigation action (e.g. [navigationActionPush]); used for
///   [navigationAction]
///
/// Returns a [Map<String, String>] keyed by OTel semantic convention
/// attribute names, suitable for use with `attributesFromMap` or
/// `ReadableSpanData.fromRaw`.
Map<String, String> viewSpanAttributes(String viewName, String action) {
  return {
    screenName: viewName,
    navigationAction: action,
  };
}

/// OTel semantic convention key: screen or view name.
const String screenName = 'screen.name';

/// OTel semantic convention key: navigation action (push, pop, replace).
const String navigationAction = 'navigation.action';

/// Navigation action value: route was pushed onto the stack.
const String navigationActionPush = 'push';

/// Navigation action value: route was popped from the stack.
const String navigationActionPop = 'pop';

/// Navigation action value: current route was replaced.
const String navigationActionReplace = 'replace';
