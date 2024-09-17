import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class LogsDemo extends StatefulWidget {
  const LogsDemo({Key? key}) : super(key: key);

  @override
  State<LogsDemo> createState() => _LogsDemoState();
}

class _LogsDemoState extends State<LogsDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = 'message';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _controller,
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance
                  .logInfo(_controller.text, properties: {'key': 'value'}),
              child: const Text('Log Info'),
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance
                  .logWarning(_controller.text, properties: {'key': 'value'}),
              child: const Text('Log Warning'),
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance
                  .logError(_controller.text, properties: {'key': 'value'}),
              child: const Text('Log Error'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
