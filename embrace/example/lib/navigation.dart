import 'package:embrace/embrace.dart';
import 'package:flutter/material.dart';

class EmbraceNavigationDemo extends StatelessWidget {
  const EmbraceNavigationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/page1',
      home: const _Page1(),
      navigatorObservers: [EmbraceNavigationObserver()],
    );
  }
}

class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page1'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) {
                  return const _Page2();
                },
              ),
            );
          },
          child: const Text('Open Page2'),
        ),
      ),
    );
  }
}

class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page2'),
      ),
    );
  }
}
