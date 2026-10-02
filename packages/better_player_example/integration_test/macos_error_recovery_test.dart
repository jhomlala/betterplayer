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
        '  [E2E macOS] STARTING: Error Recovery & Accurate Seek\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E macOS] FINISHED: Error Recovery & Accurate Seek\n'
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
      try {
        await tester.ensureVisible(playPauseButton.first);
        await tester.pump(const Duration(milliseconds: 200));
      } catch (_) {}
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Accurate seek on dedicated Seek E2E page', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to Seek E2E Page
      final navigateSeekButton = findById('better_player_e2e_navigate_seek');
      await scrollAndTap(tester: tester, finder: navigateSeekButton);

      final seekInitialized = findById('better_player_e2e_seek_initialized');
      await pumpUntilFound(
        tester: tester,
        finder: seekInitialized,
        timeout: const Duration(seconds: 25),
      );

      // 2. Seek 10s and verify
      final seek10sButton = findById('better_player_e2e_seek_10s_button');
      await scrollAndTap(tester: tester, finder: seek10sButton);

      final seek10sVerified = findById('better_player_e2e_seek_10s_verified');
      await pumpUntilFound(
        tester: tester,
        finder: seek10sVerified,
        timeout: const Duration(seconds: 15),
      );
    });
  });
}
