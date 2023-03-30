import 'dart:io' show Platform;

import 'package:embrace/embrace_samples.dart';
import 'package:flutter/material.dart';

/// Demos different error types in Flutter/Dart.
///
/// Dart Assert: https://dart.dev/guides/language/language-tour#assert
/// Dart Exceptions: https://dart.dev/guides/language/language-tour#exceptions
/// Flutter error handling: https://docs.flutter.dev/testing/errors#errors-caught-by-flutter
/// Dart Asynchrony: https://dart.dev/guides/language/language-tour#asynchrony-support
/// Foreign Function Interface errors: https://dart.dev/guides/libraries/c-interop
///
/// It is worth noting that in debug mode Flutter runs a Dart VM. In release
/// mode, Flutter compiles Dart to C/C++ code. This complicates error handling
/// as Embrace needs to support both.
///
/// https://docs.flutter.dev/resources/architectural-overview
///
class ErrorDemo extends StatelessWidget {
  const ErrorDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Errors')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerCaughtException,
                child: Text('Caught exception'),
              ),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerUncaughtException,
                child: Text('Throw exception'),
              ),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerUncaughtError,
                child: Text('Throw error'),
              ),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerUncaughtObject,
                child: Text('Throw object'),
              ),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerAssert,
                child: Text('Trigger assert (debug mode only)'),
              ),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerUncaughtExceptionAsync,
                child: Text('Trigger exception (async)'),
              ),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerNativeSdkError,
                child: Text('Native SDK exception'),
              ),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerRaisedSignal,
                child: Text('Native SDK raise signal'),
              ),
              if (Platform.isAndroid)
                const ElevatedButton(
                  onPressed: EmbraceSamples.triggerAnr,
                  child: Text('Trigger ANR'),
                )
              else
                const SizedBox(),
              const ElevatedButton(
                onPressed: EmbraceSamples.triggerMethodChannelError,
                child: Text('Method channel error'),
              ),

              // for other common render errors, see:
              // https://docs.flutter.dev/testing/common-errors#renderbox-was-not-laid-out
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<RenderflexOverflowWidget>(
                      builder: (context) => const RenderflexOverflowWidget(),
                    ),
                  );
                },
                child: const Text('Renderflex overflow error'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<StateDuringBuildWidget>(
                      builder: (context) => const StateDuringBuildWidget(),
                    ),
                  );
                },
                child: const Text('setState during build'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<UnboundInputDecoratorWidget>(
                      builder: (context) => const UnboundInputDecoratorWidget(),
                    ),
                  );
                },
                child: const Text('Unbound input decorator'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<UnboundVerticalViewportWidget>(
                      builder: (context) =>
                          const UnboundVerticalViewportWidget(),
                    ),
                  );
                },
                child: const Text('Unbound vertical viewport'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RenderflexOverflowWidget extends StatelessWidget {
  const RenderflexOverflowWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.message),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: Theme.of(context).textTheme.headline4),
            const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed'
                ' do eiusmod tempor incididunt ut labore et dolore magna '
                'aliqua. Ut enim ad minim veniam, quis nostrud '
                'exercitation ullamco laboris nisi ut aliquip ex ea '
                'commodo consequat.'),
          ],
        ),
      ],
    );
  }
}

class StateDuringBuildWidget extends StatelessWidget {
  const StateDuringBuildWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't do this in production.
    showDialog<Widget>(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Alert Dialog'),
        );
      },
    );

    return Center(
      child: Column(
        children: const <Widget>[
          Text('Show Material Dialog'),
        ],
      ),
    );
  }
}

class UnboundInputDecoratorWidget extends StatelessWidget {
  const UnboundInputDecoratorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Unbounded Width of the TextField'),
        ),
        body: Row(
          children: const [
            TextField(),
          ],
        ),
      ),
    );
  }
}

class UnboundVerticalViewportWidget extends StatelessWidget {
  const UnboundVerticalViewportWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          const Text('Header'),
          ListView(
            children: const <Widget>[
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Map'),
              ),
              ListTile(
                leading: Icon(Icons.subway),
                title: Text('Subway'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
