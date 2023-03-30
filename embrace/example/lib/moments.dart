import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class MomentsDemo extends StatefulWidget {
  const MomentsDemo({Key? key}) : super(key: key);

  @override
  State<MomentsDemo> createState() => _MomentsDemoState();
}

class _MomentsDemoState extends State<MomentsDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = 'name';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moments')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _controller,
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance.startMoment(
                _controller.text,
                properties: {'someOtherKey': 'someOtherValue'},
              ),
              child: const Text('Start Moment'),
            ),
            ElevatedButton(
              onPressed: () => Embrace.instance.endMoment(
                _controller.text,
                properties: {'someOtherKey': 'someOtherValue'},
              ),
              child: const Text('End Moment'),
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
