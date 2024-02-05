import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class UserDemo extends StatefulWidget {
  const UserDemo({Key? key}) : super(key: key);

  @override
  State<UserDemo> createState() => _UserDemoState();
}

class _UserDemoState extends State<UserDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _controller,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () =>
                      Embrace.instance.setUserIdentifier(_controller.text),
                  child: const Text('Set Identifier'),
                ),
                ElevatedButton(
                  onPressed: Embrace.instance.clearUserIdentifier,
                  child: const Text('Clear Identifier'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () =>
                      Embrace.instance.setUserName(_controller.text),
                  child: const Text('Set Name'),
                ),
                ElevatedButton(
                  onPressed: Embrace.instance.clearUserName,
                  child: const Text('Clear Name'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () =>
                      Embrace.instance.setUserEmail(_controller.text),
                  child: const Text('Set Email'),
                ),
                ElevatedButton(
                  onPressed: Embrace.instance.clearUserEmail,
                  child: const Text('Clear Email'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: Embrace.instance.setUserAsPayer,
                  child: const Text('Set As Payer'),
                ),
                ElevatedButton(
                  onPressed: Embrace.instance.clearUserAsPayer,
                  child: const Text('Clear As Payer'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () =>
                      Embrace.instance.addUserPersona(_controller.text),
                  child: const Text('Add Persona'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Embrace.instance.clearUserPersona(_controller.text),
                  child: const Text('Clear Persona'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: Embrace.instance.clearAllUserPersonas,
              child: const Text('Clear All Personas'),
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
