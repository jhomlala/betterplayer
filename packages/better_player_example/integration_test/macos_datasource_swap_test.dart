import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('macOS data source swap and list player test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Start with MP4
    final setupMp4Button = findById('better_player_e2e_setup_mp4');
    await scrollAndTap(tester, setupMp4Button);

    final playPauseButton = findById(
      'better_player_cupertino_controls_play_pause_button',
    );
    await pumpUntilFound(tester, playPauseButton);

    // 2. Swap to HLS
    final setupHlsButton = findById('better_player_e2e_setup_hls');
    await scrollAndTap(tester, setupHlsButton);
    await pumpUntilFound(
      tester,
      playPauseButton,
      timeout: const Duration(seconds: 25),
    );

    // 3. Verify it is interactive
    await tester.tap(playPauseButton);
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Swap back to MP4
    await scrollAndTap(tester, setupMp4Button);
    await pumpUntilFound(tester, playPauseButton);

    // 5. Visibility cycle verification
    final visibilityCycleButton = findById(
      'better_player_e2e_visibility_cycle_button',
    );
    await scrollAndTap(tester, visibilityCycleButton);

    final visibilityStatus = findById(
      'better_player_e2e_visibility_callback_status',
    );
    await pumpUntilFound(tester, visibilityStatus);

    // 6. Playlist verification
    final playlistButton = findById('better_player_e2e_playlist_button');
    await scrollAndTap(tester, playlistButton);

    final playlistStatus = findById('better_player_e2e_playlist_status');
    await pumpUntilFound(tester, playlistStatus);

    // 7. List player and mid-initialization disposal verification
    final listPlayerButton = findById('better_player_e2e_list_player_button');
    await scrollAndTap(tester, listPlayerButton);

    final listPlayerStatus = findById('better_player_e2e_list_player_status');
    await pumpUntilFound(tester, listPlayerStatus);
  });
}
