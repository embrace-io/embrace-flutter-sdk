import 'package:embrace_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E', () {
    testWidgets('smokeTest', (tester) async {
      // checks the example app runs
      app.main();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Errors'));
    });
  });
}
