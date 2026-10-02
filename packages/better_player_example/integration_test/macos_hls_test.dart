import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('macOS HLS streaming test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Setup HLS Data Source
    final setupHlsButton = findById('better_player_e2e_setup_hls');
    await scrollAndTap(tester, setupHlsButton);

    // 2. Wait for video controls
    final playPauseButton = findById(
      'better_player_cupertino_controls_play_pause_button',
    );
    await pumpUntilFound(
      tester,
      playPauseButton,
      timeout: const Duration(seconds: 30),
    );

    // 3. Play/Pause toggle
    await tester.tap(playPauseButton);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(playPauseButton);
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Skip testing
    final skipForward = findById(
      'better_player_cupertino_controls_skip_forward_button',
    );
    if (skipForward.evaluate().isNotEmpty) {
      await tester.tap(skipForward);
      await tester.pump(const Duration(milliseconds: 500));
    }

    final skipBack = findById(
      'better_player_cupertino_controls_skip_back_button',
    );
    if (skipBack.evaluate().isNotEmpty) {
      await tester.tap(skipBack);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 5. Mute/Unmute
    final muteButton = findById('better_player_cupertino_controls_mute_button');
    if (muteButton.evaluate().isNotEmpty) {
      await tester.tap(muteButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(muteButton);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 6. Speed Selection (2.0x)
    final moreButton = findById('better_player_cupertino_controls_more_button');
    await tapWhenReady(tester, moreButton);

    final speedMenu = findById('better_player_overflow_menu_playback_speed');
    await tapWhenReady(tester, speedMenu);

    final speed2x = findById('better_player_overflow_menu_speed_2.0');
    await scrollAndTap(tester, speed2x);
    await waitModalClosed(tester);

    // 7. Quality Selection (Auto + variants)
    await tapWhenReady(tester, moreButton);
    final qualityMenu = findById('better_player_overflow_menu_quality');
    await tapWhenReady(tester, qualityMenu);

    final qualityAuto = findById('better_player_overflow_menu_quality_auto');
    await pumpUntilFound(tester, qualityAuto);

    final quality1 = findById('better_player_overflow_menu_quality_1');
    if (quality1.evaluate().isNotEmpty) {
      await tester.tap(quality1, warnIfMissed: false);
      await waitModalClosed(tester);

      // Switch back to Auto
      await tapWhenReady(tester, moreButton);
      await tapWhenReady(tester, qualityMenu);
      await tapWhenReady(tester, qualityAuto);
      await waitModalClosed(tester);
    } else {
      await tester.tap(qualityAuto, warnIfMissed: false);
      await waitModalClosed(tester);
    }

    // 8. Seeking
    final progressBar = findById('better_player_cupertino_progress_bar');
    if (progressBar.evaluate().isNotEmpty) {
      try {
        await tester.ensureVisible(progressBar.first);
        await tester.pump(const Duration(milliseconds: 200));
      } catch (_) {}
      await tester.tap(progressBar.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 9. Fullscreen
    final expandButton = findById(
      'better_player_cupertino_controls_expand_button',
    );
    if (expandButton.evaluate().isNotEmpty) {
      try {
        await tester.ensureVisible(expandButton.first);
        await tester.pump(const Duration(milliseconds: 200));
      } catch (_) {}
      await tester.tap(expandButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
