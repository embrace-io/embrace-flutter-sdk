import 'package:embrace/embrace.dart';
import 'package:embrace_example/breadcrumbs.dart';
import 'package:embrace_example/current_session.dart';
import 'package:embrace_example/errors.dart';
import 'package:embrace_example/isolates.dart';
import 'package:embrace_example/last_run_end_state.dart';
import 'package:embrace_example/logs.dart';
import 'package:embrace_example/navigation.dart';
import 'package:embrace_example/network.dart';
import 'package:embrace_example/push_notifications.dart';
import 'package:embrace_example/session_properties.dart';
import 'package:embrace_example/tracing_api.dart';
import 'package:embrace_example/user.dart';
import 'package:embrace_example/views.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await Embrace.instance.start(() => runApp(const EmbraceDemo()));
}

class EmbraceDemo extends StatelessWidget {
  const EmbraceDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: EmbraceMenu());
  }
}

class EmbraceMenu extends StatefulWidget {
  const EmbraceMenu({Key? key}) : super(key: key);

  @override
  State<EmbraceMenu> createState() => _EmbraceMenuState();
}

class _EmbraceMenuState extends State<EmbraceMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Embrace Example App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: ListView(
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<BreadcrumbDemo>(
                      builder: (context) => const BreadcrumbDemo(),
                    ),
                  );
                },
                child: const Text('Breadcrumbs'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<PushNotificationsDemo>(
                      builder: (context) => const PushNotificationsDemo(),
                    ),
                  );
                },
                child: const Text('Push Notifications'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<LogsDemo>(
                      builder: (context) => const LogsDemo(),
                    ),
                  );
                },
                child: const Text('Logs'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<ViewsDemo>(
                      builder: (context) => const ViewsDemo(),
                    ),
                  );
                },
                child: const Text('Views'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<ErrorDemo>(
                      builder: (context) => const EmbraceNavigationDemo(),
                    ),
                  );
                },
                child: const Text('Navigation'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<UserDemo>(
                      builder: (context) => const UserDemo(),
                    ),
                  );
                },
                child: const Text('User'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<SessionPropertiesDemo>(
                      builder: (context) => const SessionPropertiesDemo(),
                    ),
                  );
                },
                child: const Text('Session Properties'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<NetworkDemo>(
                      builder: (context) => const NetworkDemo(),
                    ),
                  );
                },
                child: const Text('Network'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<ErrorDemo>(
                      builder: (context) => const ErrorDemo(),
                    ),
                  );
                },
                child: const Text('Errors'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<IsolatesDemo>(
                      builder: (context) => const IsolatesDemo(),
                    ),
                  );
                },
                child: const Text('Isolate Errors'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<LastRunEndStateDemo>(
                      builder: (context) => const LastRunEndStateDemo(),
                    ),
                  );
                },
                child: const Text('Last session end state'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<CurrentSessionDemo>(
                      builder: (context) => const CurrentSessionDemo(),
                    ),
                  );
                },
                child: const Text('Current session ID / End session'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<TracingApiDemo>(
                      builder: (context) => const TracingApiDemo(),
                    ),
                  );
                },
                child: const Text('Tracing API'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
