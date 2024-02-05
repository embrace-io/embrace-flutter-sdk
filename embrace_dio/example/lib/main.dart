import 'package:dio/dio.dart';
import 'package:embrace/embrace.dart';
import 'package:embrace_dio/embrace_dio.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await Embrace.instance.start(() => runApp(const EmbraceDioDemo()));
}

class EmbraceDioDemo extends StatelessWidget {
  const EmbraceDioDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: EmbraceDioMenu());
  }
}

class EmbraceDioMenu extends StatefulWidget {
  const EmbraceDioMenu({Key? key}) : super(key: key);

  @override
  State<EmbraceDioMenu> createState() => _EmbraceDioMenuState();
}

class _EmbraceDioMenuState extends State<EmbraceDioMenu> {
  late final _dio = Dio();

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(EmbraceInterceptor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            children: <Widget>[
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
      ),
    );
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> sendAndLogRequest(HttpMethod method) async {
    switch (method) {
      case HttpMethod.put:
        await _dio.put('https://httpbin.org/put');
        break;
      case HttpMethod.post:
        await _dio.post('https://httpbin.org/post');
        break;
      case HttpMethod.patch:
        await _dio.patch('https://httpbin.org/patch');
        break;
      case HttpMethod.delete:
        await _dio.delete('https://httpbin.org/delete');
        break;
      case HttpMethod.get:
        await _dio.get('https://httpbin.org/get');
        break;
      case HttpMethod.other:
        await _dio.get('https://httpbin.org/get');
        break;
    }
  }
}
