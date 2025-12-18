import 'package:embrace_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E', () {
    testWidgets('smokeTest', (tester) async {
      print('starting test');
      await app.main();
      print('starting pump and settle test');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      print('starting ensure visible errors test');
      await tester.ensureVisible(find.text('Errors'));
    },
    timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
