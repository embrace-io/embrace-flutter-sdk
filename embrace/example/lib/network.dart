import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworkDemo extends StatefulWidget {
  const NetworkDemo({super.key});

  @override
  State<NetworkDemo> createState() => _NetworkDemoState();
}

class _NetworkDemoState extends State<NetworkDemo> {
  final TextEditingController _controller = TextEditingController();
  late final http.Client _client = EmbraceHttpClient();

  @override
  void initState() {
    super.initState();
    _controller.text = 'https://httpbin.org/get';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _controller,
            ),
            ElevatedButton(
              onPressed: () => sendAndLogRequest(HttpMethod.get),
              child: const Text('Get'),
            ),
            ElevatedButton(
              onPressed: () => sendAndLogRequest(HttpMethod.post),
              child: const Text('Post'),
            ),
            ElevatedButton(
              onPressed: () => sendAndLogRequest(HttpMethod.put),
              child: const Text('Put'),
            ),
            ElevatedButton(
              onPressed: () => sendAndLogRequest(HttpMethod.patch),
              child: const Text('Patch'),
            ),
            ElevatedButton(
              onPressed: () => sendAndLogRequest(HttpMethod.delete),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> sendAndLogRequest(HttpMethod method) async {
    final url = Uri.parse(_controller.text);

    switch (method) {
      case HttpMethod.put:
        await _client.put(url);
        break;
      case HttpMethod.post:
        await _client.post(url);
        break;
      case HttpMethod.patch:
        await _client.patch(url);
        break;
      case HttpMethod.delete:
        await _client.delete(url);
        break;
      case HttpMethod.get:
        await _client.get(url);
        break;
      case HttpMethod.other:
        await _client.get(url);
        break;
    }
  }
}
