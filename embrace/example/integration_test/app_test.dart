import 'package:embrace_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E', () {
    testWidgets('smokeTest', (tester) async {
      // checks the example app runs
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.ensureVisible(find.text('Errors'));
    });
  });
}
