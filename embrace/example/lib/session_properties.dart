import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class SessionPropertiesDemo extends StatefulWidget {
  const SessionPropertiesDemo({Key? key}) : super(key: key);

  @override
  State<SessionPropertiesDemo> createState() => _SessionPropertiesDemoState();
}

class _SessionPropertiesDemoState extends State<SessionPropertiesDemo> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController.text = 'key';
    _valueController.text = 'value';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Properties')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _keyController,
            ),
            TextFormField(
              controller: _valueController,
            ),
            ElevatedButton(
              onPressed: () {
                Embrace.instance.addSessionProperty(
                  _keyController.text,
                  _valueController.text,
                );
              },
              child: const Text('Add'),
            ),
            ElevatedButton(
              onPressed: () {
                Embrace.instance.removeSessionProperty(_keyController.text);
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}
