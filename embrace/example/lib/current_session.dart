import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class CurrentSessionDemo extends StatefulWidget {
  const CurrentSessionDemo({Key? key}) : super(key: key);

  @override
  State<CurrentSessionDemo> createState() => _CurrentSessionDemoState();
}

class _CurrentSessionDemoState extends State<CurrentSessionDemo> {
  String? _currentsessionId;
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current session')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            children: <Widget>[
              Text(
                "Current session id is:\n${_currentsessionId ?? 'No current session id'}",
              ),
              Text(
                "Current device id is:\n${_currentDeviceId ?? 'No current device id'}",
              ),
              ElevatedButton(
                onPressed: _endSession,
                child: const Text('End session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateIds() {
    Embrace.instance.getCurrentSessionId().then((sessionId) {
      setState(() {
        _currentsessionId = sessionId;
      });
    });

    Embrace.instance.getDeviceId().then((deviceId) {
      setState(() {
        _currentDeviceId = deviceId;
      });
    });
  }

  void _endSession() {
    Embrace.instance.endSession();
    _updateIds();
  }
}
