# embrace_go_router

A package to enable the `embrace` plugin to automatically track navigation for apps using go_router.

## Usage

### Simple apps (no `StatefulShellRoute`)

Add `EmbraceGoRouterObserver` to the `observers` list of your `GoRouter` instance.

```dart
import 'package:go_router/go_router.dart';
import 'package:embrace_go_router/embrace_go_router.dart';

final router = GoRouter(
  observers: [EmbraceGoRouterObserver()],
  routes: [...],
);
```

### Apps using `StatefulShellRoute`

Pass the `GoRouter` instance directly. This hooks into go_router's `routeInformationProvider`, capturing every route change including those in sub-navigators that a `NavigatorObserver` would miss.

```dart
import 'package:go_router/go_router.dart';
import 'package:embrace_go_router/embrace_go_router.dart';

final _router = GoRouter(routes: [...]);
late final _observer = EmbraceGoRouterObserver(router: _router);

@override
void dispose() {
  _observer.dispose();
  super.dispose();
}
```

Do **not** also add the observer to `GoRouter.observers` when using this mode.
