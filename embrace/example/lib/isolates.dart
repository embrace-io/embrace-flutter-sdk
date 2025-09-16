// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class IsolatesDemo extends StatelessWidget {
  const IsolatesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isolate error'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: runComputeProcess,
              child: const Text('Run process with compute'),
            ),
            ElevatedButton(
              onPressed: runIsolateProcess,
              child: const Text('Run process in an Isolate'),
            ),
          ],
        ),
      ),
    );
  }

  /// The easiest way to run a proccess in an Isolate is by using the
  /// `compute` method.
  /// https://api.flutter.dev/flutter/foundation/compute-constant.html
  Future<void> runComputeProcess() async {
    try {
      await compute(
        (String message) {
          print(message);
          throw Exception();
        },
        'Isolated process using compute',
      );
    } catch (e) {
      print('An error in an Isolated that uses compute is caught by '
          'default by the Embrace SDK');
      throw Exception();
    }
  }

  /// When working with an isolate it is possible to forward uncaught errors 
  /// to the root isolate via the `onError` port
  /// 
  /// The message received by the [ReceivePort] will be a two-item array
  /// that will contain the Error message as a String in the first place.
  /// The second item will be the stack trace also as a String. Then it can
  /// converted to a `StackTrace` object using `StackTrace.fromString` 
  /// constructor
  ///
  /// Embrace can automatically handle this error if its thrown in the root 
  /// isolate by using `Error.throwWithStackTrace(error, stackTrace)` or
  /// can be logged directly using 
  /// `Embrace.instance.logDartError(error, stackTrace)`
  /// 
  /// Don't forget to close all ports if the error is fatal or the exit event
  /// is triggered
  Future<void> runIsolateProcess() async {
    final exitPort = ReceivePort();
    final errorPort = ReceivePort();
    exitPort.listen((dynamic message) {
      errorPort.close();
      exitPort.close();
    });
    errorPort.listen((dynamic message) {
      errorPort.close();
      exitPort.close();

      final params = message as List<dynamic>;
      final error = params[0] as String;
      final stackTrace = StackTrace.fromString(params[1] as String);

      // Option 1: Throw the error in the root Isolate and
      // let Embrace SDK catch it automatically
      Error.throwWithStackTrace(error, stackTrace);

      // Option 2: Log the error into the Embrace SDK directly
      // Embrace.instance.logDartError(error, stackTrace);
    });
    await Isolate.spawn(
      (String message) {
        print(message);
        throw Exception();
      },
      'Isolated process',
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );
  }
}
