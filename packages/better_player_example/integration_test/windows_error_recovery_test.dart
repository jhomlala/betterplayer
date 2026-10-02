import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 4: Error Recovery & Accurate Seek', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Error Recovery & Accurate Seek\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Error Recovery & Accurate Seek\n'
        '========================================',
      );
    });

    testWidgets('Error recovery from invalid URL to valid MP4', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Trigger error state with invalid URL
      final setupErrorButton = findById('better_player_e2e_setup_error');
      await scrollAndTap(tester: tester, finder: setupErrorButton);

      final errorText = findById('better_player_e2e_error_text');
      await pumpUntilFound(
        tester: tester,
        finder: errorText,
        timeout: const Duration(seconds: 15),
      );

      // 2. Recover from error with valid MP4
      final setupMp4Button = findById('better_player_e2e_setup_mp4');
      await scrollAndTap(tester: tester, finder: setupMp4Button);

      await pumpUntilNotFound(
        tester: tester,
        finder: errorText,
        timeout: const Duration(seconds: 15),
      );

      final playPauseButton = findById(
        'better_player_cupertino_controls_play_pause_button',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playPauseButton,
        timeout: const Duration(seconds: 15),
      );

      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Accurate seek to 30s timestamp', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to Seek E2E Page
      final navigateSeekButton = findById('better_player_e2e_navigate_seek');
      await scrollAndTap(tester: tester, finder: navigateSeekButton);

      // 2. Wait for player to be initialized
      final seekInitialized = findById('seek_e2e_initialized');
      await pumpUntilFound(
        tester: tester,
        finder: seekInitialized,
      );

      // 3. Trigger 30s Seek
      final seek30sButton = findById('seek_e2e_button_30s');
      await tapWhenReady(tester: tester, finder: seek30sButton);

      // 4. Verify accurate seek completed
      final seekCompleted = findById('seek_e2e_completed');
      await pumpUntilFound(
        tester: tester,
        finder: seekCompleted,
        timeout: const Duration(seconds: 15),
      );
      expect(seekCompleted, findsOneWidget);
    });
  });
}
