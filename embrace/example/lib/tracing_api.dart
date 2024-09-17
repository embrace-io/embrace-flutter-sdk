import 'package:embrace/embrace.dart';
import 'package:embrace/embrace_api.dart';
import 'package:flutter/material.dart';

class TracingApiDemo extends StatefulWidget {
  const TracingApiDemo({Key? key}) : super(key: key);

  @override
  State<TracingApiDemo> createState() => _TracingApiDemoState();
}

class _TracingApiDemoState extends State<TracingApiDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracing API')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: _startSpan,
                child: const Text('Start & stop span'),
              ),
              ElevatedButton(
                onPressed: _recordCompletedSpan,
                child: const Text('Record completed span'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startSpan() async {
    final span = await Embrace.instance.startSpan('my-span');

    if (span != null) {
      final childSpan =
          await Embrace.instance.startSpan('child-span', parent: span);
      await childSpan?.stop();
      await span.addAttribute('my-attribute-key', 'my-attribute-value');
      await span.addEvent(
        'my-event-name',
        attributes: {
          'my-event-attribute-key': 'my-event-attribute-value',
        },
      );
      await span.stop();
      return;
    }
  }

  void _recordCompletedSpan() async {
    final start = DateTime.now().millisecondsSinceEpoch - 1000;
    final end = start + 500;
    final result = await Embrace.instance.recordCompletedSpan(
      'my-recorded-span',
      start,
      end,
      attributes: {'my-span-key': 'my-span-value'},
      events: [
        EmbraceSpanEvent(
          name: 'my-span-event',
          attributes: {'my-event-key': 'my-event-value'},
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        )
      ],
    );
  }
}
