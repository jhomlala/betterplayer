import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('macOS core playback flow test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Wait for video controls
    final playPauseButton = findById(
      'better_player_cupertino_controls_play_pause_button',
    );
    await pumpUntilFound(tester, playPauseButton);

    // 2. Play / Pause toggle
    await tester.tap(playPauseButton);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(playPauseButton);
    await tester.pump(const Duration(milliseconds: 500));

    // 3. Skip testing (15s forward, 15s back)
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

    // 4. Mute / Unmute
    final muteButton = findById('better_player_cupertino_controls_mute_button');
    if (muteButton.evaluate().isNotEmpty) {
      await tester.tap(muteButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(muteButton);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 5. Speed Selection test (2.0x)
    final moreButton = findById('better_player_cupertino_controls_more_button');
    await tapWhenReady(tester, moreButton);

    final speedMenu = findById('better_player_overflow_menu_playback_speed');
    await tapWhenReady(tester, speedMenu);

    final speed2x = findById('better_player_overflow_menu_speed_2.0');
    await scrollAndTap(tester, speed2x);

    // 6. Quality Selection test (Auto)
    await tapWhenReady(tester, moreButton);
    final qualityMenu = findById('better_player_overflow_menu_quality');
    await tapWhenReady(tester, qualityMenu);

    final qualityAuto = findById('better_player_overflow_menu_quality_auto');
    await tapWhenReady(tester, qualityAuto);

    // 7. Subtitles Selection test (Memory -> None -> Memory)
    await tapWhenReady(tester, moreButton);
    final subtitlesMenu = findById('better_player_overflow_menu_subtitles');
    await tapWhenReady(tester, subtitlesMenu);

    final subtitlesNone = findById(
      'better_player_overflow_menu_subtitles_none',
    );
    await tapWhenReady(tester, subtitlesNone);

    await tapWhenReady(tester, moreButton);
    await tapWhenReady(tester, subtitlesMenu);

    final subtitlesMemory = findById(
      'better_player_overflow_menu_subtitles_memory',
    );
    await tapWhenReady(tester, subtitlesMemory);

    // 8. Verify all core events fired
    final eventsVerified = findById('better_player_e2e_events_verified');
    await pumpUntilFound(tester, eventsVerified);

    // 9. Runtime Controls Configuration Hotswap
    final runtimeConfigButton = findById(
      'better_player_e2e_runtime_config_button',
    );
    await scrollAndTap(tester, runtimeConfigButton);

    final runtimeConfigStatus = findById(
      'better_player_e2e_runtime_config_status',
    );
    await pumpUntilFound(tester, runtimeConfigStatus);

    // 10. Controls Theme Hotswap (Cupertino -> Material -> Cupertino)
    final toggleThemeButton = findById('better_player_e2e_toggle_theme_button');
    await scrollAndTap(tester, toggleThemeButton);

    final materialPlayPause = findById(
      'better_player_material_controls_play_pause_button',
    );
    await pumpUntilFound(tester, materialPlayPause);

    await scrollAndTap(tester, toggleThemeButton);
    await pumpUntilFound(tester, playPauseButton);

    // 11. Seeking
    final progressBar = findById('better_player_cupertino_progress_bar');
    if (progressBar.evaluate().isNotEmpty) {
      await tester.tap(progressBar);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 12. Fullscreen toggle
    final expandButton = findById(
      'better_player_cupertino_controls_expand_button',
    );
    if (expandButton.evaluate().isNotEmpty) {
      await tester.tap(expandButton);
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
