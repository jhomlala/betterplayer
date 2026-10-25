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
        '  [E2E Linux] STARTING: Data Source Swap & List Player\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] FINISHED: Data Source Swap & List Player\n'
        '========================================',
      );
    });

    testWidgets('Data source swap between MP4 and HLS', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Start with MP4
      final setupMp4Button = findById('better_player_e2e_setup_mp4');
      await scrollAndTap(tester: tester, finder: setupMp4Button);
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

      // 2. Swap to HLS
      final setupHlsButton = findById('better_player_e2e_setup_hls');
      await scrollAndTap(tester: tester, finder: setupHlsButton);
      final hlsInitialized = findById('better_player_e2e_hls_initialized');
      await pumpUntilFound(
        tester: tester,
        finder: hlsInitialized,
        timeout: const Duration(seconds: 45),
      );
      await pumpUntilFound(tester: tester, finder: playPauseButton);

      // 3. Swap back to MP4
      await scrollAndTap(tester: tester, finder: setupMp4Button);
      await pumpUntilFound(
        tester: tester,
        finder: mp4Initialized,
        timeout: const Duration(seconds: 30),
      );
      await pumpUntilFound(tester: tester, finder: playPauseButton);

      // 4. Verify player is responsive after swaps
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('List player setup and verification', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final setupListButton = findById('better_player_e2e_setup_list_player');
      await scrollAndTap(tester: tester, finder: setupListButton);

      final listStatus = findById('better_player_e2e_list_player_status');
      await pumpUntilFound(
        tester: tester,
        finder: listStatus,
        timeout: const Duration(seconds: 30),
      );

      expect(listStatus, findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Playlist mode setup and playback', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final setupPlaylistButton = findById('better_player_e2e_setup_playlist');
      await scrollAndTap(tester: tester, finder: setupPlaylistButton);

      final playlistStatus = findById('better_player_e2e_playlist_status');
      await pumpUntilFound(
        tester: tester,
        finder: playlistStatus,
        timeout: const Duration(seconds: 30),
      );

      expect(playlistStatus, findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
