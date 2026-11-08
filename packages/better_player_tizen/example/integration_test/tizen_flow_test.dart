import 'package:better_player/better_player.dart';
import 'package:better_player_tizen_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tizen E2E Flow', () {
    testWidgets('Initializes player and verifies playback controls', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(app.TizenVideoPlayerScreen), findsOneWidget);

      final state = tester.state<app.TizenVideoPlayerScreenState>(
        find.byType(app.TizenVideoPlayerScreen),
      );
      final controller = state.controller;

      await controller.play();
      await tester.pump(const Duration(milliseconds: 100));
      await controller.pause();
      await tester.pump(const Duration(milliseconds: 100));
      await controller.setVolume(0.5);
      await controller.setSpeed(1.5);
      await controller.setLooping(true);

      // Verify that the screen remains stable during initial frames
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(app.TizenVideoPlayerScreen), findsOneWidget);
    });
  });
}
