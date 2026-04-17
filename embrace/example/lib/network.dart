import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
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
  String _responseBody = '';

  @override
  void initState() {
    super.initState();
    _controller.text = 'https://httpbin.org/headers';
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
            const Divider(),
            ElevatedButton(
              onPressed: _sendWithActiveSpan,
              child: const Text('Get (with active OTel span)'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Response (check for Traceparent header):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _responseBody,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
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

  Future<void> _sendWithActiveSpan() async {
    final tracer = OTelAPI.tracerProvider().getTracer('network-demo');
    final span = tracer.startSpan('network-request-span');
    try {
      await sendAndLogRequest(HttpMethod.get);
    } finally {
      span.end();
    }
  }

  Future<void> sendAndLogRequest(HttpMethod method) async {
    final url = Uri.parse(_controller.text);
    http.Response? response;

    switch (method) {
      case HttpMethod.put:
        response = await _client.put(url);
        break;
      case HttpMethod.post:
        response = await _client.post(url);
        break;
      case HttpMethod.patch:
        response = await _client.patch(url);
        break;
      case HttpMethod.delete:
        response = await _client.delete(url);
        break;
      case HttpMethod.get:
        response = await _client.get(url);
        break;
      case HttpMethod.other:
        response = await _client.get(url);
        break;
    }

    setState(() {
      _responseBody = response?.body ?? '';
    });
  }
}
