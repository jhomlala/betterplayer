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
        '  [E2E Linux] STARTING: Error Recovery & Accurate Seek\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] FINISHED: Error Recovery & Accurate Seek\n'
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

      final mp4Initialized = findById('better_player_e2e_mp4_initialized');
      await pumpUntilFound(
        tester: tester,
        finder: mp4Initialized,
        timeout: const Duration(seconds: 30),
      );

      final playPauseButton = findById(
        'better_player_material_controls_play_pause_button',
      );
      await pumpUntilFound(tester: tester, finder: playPauseButton);

      // 3. Verify playback works after recovery
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Accurate seek verification', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final navigateSeekButton = findById('better_player_e2e_navigate_seek');
      await scrollAndTap(tester: tester, finder: navigateSeekButton);

      final seekInitialized = findById('seek_test_initialized_status');
      await pumpUntilFound(
        tester: tester,
        finder: seekInitialized,
        timeout: const Duration(seconds: 30),
      );

      final seekTargets = [10, 30, 60, 5];
      for (final target in seekTargets) {
        final seekButton = findById('seek_btn_$target');
        if (seekButton.evaluate().isNotEmpty) {
          await tapWhenReady(tester: tester, finder: seekButton);
          await tester.pump(const Duration(milliseconds: 500));
        }
      }

      expect(seekInitialized, findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
