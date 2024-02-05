# Upgrade guide

# Upgrading from 1.4.0 to 1.5.0

Version 1.5.0 of the Embrace Flutter SDK renames some functions. This has been done to reduce
confusion & increase consistency across our SDKs.

Functions that have been marked as deprecated will still work as before, but will be removed in
the next major version release. Please upgrade when convenient, and get in touch if you have a
use-case that isn’t supported by the new API.

| Old API                              | New API                                 | Comments                         |
|--------------------------------------|-----------------------------------------|----------------------------------|
| `Embrace.instance.setUserPersona  `  | `Embrace.instance.addUserPersona`       | Renamed function for consistency |
| `Embrace.instance.endStartupMoment`  | `Embrace.instance.endAppStartup`        | Renamed function for consistency |
| `Embrace.instance.logBreadcrumb`     | `Embrace.instance.addBreadcrumb`        | Renamed function for consistency |
| `Embrace.instance.logNetworkRequest` | `Embrace.instance.recordNetworkRequest` | Renamed function for consistency |
