import 'package:better_player_tizen_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tizen E2E Flow', () {
    testWidgets('Initializes player and verifies widget tree', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(app.TizenVideoPlayerScreen), findsOneWidget);

      // Verify that the screen remains stable during initial frames
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(app.TizenVideoPlayerScreen), findsOneWidget);
    });
  });
}
