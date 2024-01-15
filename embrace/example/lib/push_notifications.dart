import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class PushNotificationsDemo extends StatefulWidget {
  const PushNotificationsDemo({Key? key}) : super(key: key);

  @override
  State<PushNotificationsDemo> createState() => _PushNotificationsDemoState();
}

class _PushNotificationsDemoState extends State<PushNotificationsDemo> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  @override
  void initState() {
    super.initState();
    _title.text = 'Notification title';
    _body.text = 'Notification body';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breadcrumbs')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _title,
            ),
            TextFormField(
              controller: _body,
            ),
            ElevatedButton(
              onPressed: () =>
                  Embrace.instance.logPushNotification(_title.text, _body.text),
              child: const Text('Log Push Notification'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }
}
