import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class ViewsDemo extends StatefulWidget {
  const ViewsDemo({Key? key}) : super(key: key);

  @override
  State<ViewsDemo> createState() => _ViewsDemoState();
}

class _ViewsDemoState extends State<ViewsDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = 'name';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Views')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _controller,
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance.startView(_controller.text),
              child: const Text('Start View'),
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance.endView(_controller.text),
              child: const Text('End View'),
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
