import 'package:embrace/embrace.dart';
import 'package:embrace_platform_interface/last_run_end_state.dart';
import 'package:flutter/material.dart';

class LastRunEndStateDemo extends StatefulWidget {
  const LastRunEndStateDemo({Key? key}) : super(key: key);

  @override
  State<LastRunEndStateDemo> createState() => _LastRunEndStateDemoState();
}

class _LastRunEndStateDemoState extends State<LastRunEndStateDemo> {
  String _lastRunEndState = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Last run end state')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: _updateLastRunEndState,
                child: const Text('Get last session state'),
              ),
              Text(_lastRunEndState),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateLastRunEndState() async {
    final lastRunEndState = await Embrace.instance.getLastRunEndState();
    switch (lastRunEndState) {
      case LastRunEndState.invalid:
        _setLastRunEndState('Invalid state');
        break;
      case LastRunEndState.crash:
        _setLastRunEndState('Last session crashed');
        break;
      case LastRunEndState.cleanExit:
        _setLastRunEndState('Last session exited cleanly');
        break;
    }
  }

  void _setLastRunEndState(String s) {
    setState(() {
      _lastRunEndState = s;
    });
  }
}
