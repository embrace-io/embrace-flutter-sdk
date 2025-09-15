import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class BreadcrumbDemo extends StatefulWidget {
  const BreadcrumbDemo({super.key});

  @override
  State<BreadcrumbDemo> createState() => _BreadcrumbDemoState();
}

class _BreadcrumbDemoState extends State<BreadcrumbDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = 'message';
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
              controller: _controller,
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance.addBreadcrumb(_controller.text),
              child: const Text('Add Breadcrumb'),
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
