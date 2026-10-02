import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 3: Data Source Swap & List Player', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Data Source Swap & List Player\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Data Source Swap & List Player\n'
        '========================================',
      );
    });

    testWidgets('Data source swap between MP4 and HLS', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Start with MP4
      final setupMp4Button = findById('better_player_e2e_setup_mp4');
      await scrollAndTap(tester: tester, finder: setupMp4Button);

      final playPauseButton = findById(
        'better_player_cupertino_controls_play_pause_button',
      );
      await pumpUntilFound(tester: tester, finder: playPauseButton);

      // 2. Swap to HLS
      final setupHlsButton = findById('better_player_e2e_setup_hls');
      await scrollAndTap(tester: tester, finder: setupHlsButton);
      await pumpUntilFound(
        tester: tester,
        finder: playPauseButton,
        timeout: const Duration(seconds: 25),
      );
      try {
        await tester.ensureVisible(playPauseButton.first);
        await tester.pump(const Duration(milliseconds: 200));
      } catch (_) {}

      // 3. Verify it is interactive
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Swap back to MP4
      await scrollAndTap(tester: tester, finder: setupMp4Button);
      await pumpUntilFound(tester: tester, finder: playPauseButton);
    });

    testWidgets('Playlist Mode Verification', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final togglePlaylistButton = findById(
        'better_player_e2e_toggle_playlist',
      );
      await scrollAndTap(tester: tester, finder: togglePlaylistButton);

      final playlistVerified = findById(
        'better_player_e2e_playlist_mode_verified',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playlistVerified,
      );
      expect(playlistVerified, findsOneWidget);
    });

    testWidgets('List Video Player Mode Verification', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final toggleListPlayerButton = findById(
        'better_player_e2e_toggle_list_player',
      );
      await scrollAndTap(tester: tester, finder: toggleListPlayerButton);

      final listPlayerVerified = findById(
        'better_player_e2e_list_player_verified',
      );
      await pumpUntilFound(
        tester: tester,
        finder: listPlayerVerified,
      );
      expect(listPlayerVerified, findsOneWidget);
    });
  });
}
