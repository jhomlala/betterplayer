import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('macOS error recovery and accurate seek test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Trigger error state with invalid URL
    final setupErrorButton = findById('better_player_e2e_setup_error');
    await scrollAndTap(tester, setupErrorButton);

    final errorText = findById('better_player_e2e_error_text');
    await pumpUntilFound(
      tester,
      errorText,
      timeout: const Duration(seconds: 15),
    );

    // 2. Recover from error with valid MP4
    final setupMp4Button = findById('better_player_e2e_setup_mp4');
    await scrollAndTap(tester, setupMp4Button);

    await pumpUntilNotFound(
      tester,
      errorText,
      timeout: const Duration(seconds: 15),
    );

    final playPauseButton = findById(
      'better_player_cupertino_controls_play_pause_button',
    );
    await pumpUntilFound(
      tester,
      playPauseButton,
      timeout: const Duration(seconds: 15),
    );
    await tester.tap(playPauseButton);
    await tester.pump(const Duration(milliseconds: 500));

    // 3. Navigate to Seek E2E Page
    final navigateSeekButton = findById('better_player_e2e_navigate_seek');
    await scrollAndTap(tester, navigateSeekButton);

    final seekInitialized = findById('better_player_e2e_seek_initialized');
    await pumpUntilFound(
      tester,
      seekInitialized,
      timeout: const Duration(seconds: 25),
    );

    // 4. Seek 10s and verify
    final seek10sButton = findById('better_player_e2e_seek_10s_button');
    await scrollAndTap(tester, seek10sButton);

    final seek10sVerified = findById('better_player_e2e_seek_10s_verified');
    await pumpUntilFound(
      tester,
      seek10sVerified,
      timeout: const Duration(seconds: 15),
    );
  });
}
