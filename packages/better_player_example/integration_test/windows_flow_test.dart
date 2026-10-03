import 'dart:io';

import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 1: Core Playback Flow', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Core Playback Flow\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Core Playback Flow\n'
        '========================================',
      );
    });

    testWidgets('Windows core playback flow test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Wait for video controls
      final playPauseButton = findById(
        'better_player_material_controls_play_pause_button',
      );
      await pumpUntilFound(tester: tester, finder: playPauseButton);

      try {
        await Process.run('nircmd', [
          'savescreenshot',
          'windows_flow_playback.png',
        ]);
      } catch (e) {
        debugPrint('Screenshot error: $e');
      }

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
      final muteButton = findById(
        'better_player_material_controls_mute_button',
      );
      if (muteButton.evaluate().isNotEmpty) {
        await tester.tap(muteButton);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(muteButton);
        await tester.pump(const Duration(milliseconds: 500));
      }

      // 5. Speed Selection test (2.0x)
      final moreButton = findById(
        'better_player_material_controls_more_button',
      );
      await tapWhenReady(tester: tester, finder: moreButton);

      final speedMenu = findById('better_player_overflow_menu_playback_speed');
      await tapWhenReady(tester: tester, finder: speedMenu);

      final speed2x = findById('better_player_overflow_menu_speed_2.0');
      await scrollAndTap(tester: tester, finder: speed2x);
      await waitModalClosed(tester: tester);

      // 6. Quality Selection test (Auto)
      await tapWhenReady(tester: tester, finder: moreButton);
      final qualityMenu = findById('better_player_overflow_menu_quality');
      await tapWhenReady(tester: tester, finder: qualityMenu);

      final qualityAuto = findById('better_player_overflow_menu_quality_auto');
      await tapWhenReady(tester: tester, finder: qualityAuto);
      await waitModalClosed(tester: tester);

      // 7. Subtitles Selection test (Memory -> None -> Memory)
      await tapWhenReady(tester: tester, finder: moreButton);
      final subtitlesMenu = findById('better_player_overflow_menu_subtitles');
      await tapWhenReady(tester: tester, finder: subtitlesMenu);

      final subtitlesNone = findById(
        'better_player_overflow_menu_subtitles_none',
      );
      await tapWhenReady(tester: tester, finder: subtitlesNone);
      await waitModalClosed(tester: tester);

      await tapWhenReady(tester: tester, finder: moreButton);
      await tapWhenReady(tester: tester, finder: subtitlesMenu);

      final subtitlesMemory = findById(
        'better_player_overflow_menu_subtitles_memory',
      );
      await tapWhenReady(tester: tester, finder: subtitlesMemory);
      await waitModalClosed(tester: tester);

      // 8. Verify all core events fired
      final eventsVerified = findById('better_player_e2e_events_verified');
      await pumpUntilFound(tester: tester, finder: eventsVerified);

      // 9. Runtime Controls Configuration Hotswap
      final runtimeConfigButton = findById(
        'better_player_e2e_runtime_config_button',
      );
      await scrollAndTap(tester: tester, finder: runtimeConfigButton);

      final runtimeConfigStatus = findById(
        'better_player_e2e_runtime_config_status',
      );
      await pumpUntilFound(tester: tester, finder: runtimeConfigStatus);

      // 10. Controls Theme Hotswap (Web -> Cupertino -> Web)
      final toggleThemeButton = findById(
        'better_player_e2e_toggle_theme_button',
      );
      await scrollAndTap(tester: tester, finder: toggleThemeButton);

      final cupertinoPlayPause = findById(
        'better_player_cupertino_controls_play_pause_button',
      );
      await pumpUntilFound(tester: tester, finder: cupertinoPlayPause);

      try {
        await Process.run('nircmd', [
          'savescreenshot',
          'windows_cupertino_controls.png',
        ]);
      } catch (_) {}

      await scrollAndTap(tester: tester, finder: toggleThemeButton);
      await pumpUntilFound(tester: tester, finder: playPauseButton);

      // 11. Seeking
      final progressBar = findById('better_player_material_progress_bar');
      if (progressBar.evaluate().isNotEmpty) {
        try {
          await tester.ensureVisible(progressBar.first);
          await tester.pump(const Duration(milliseconds: 200));
        } catch (_) {}
        await tester.tap(progressBar.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
      }

      // 12. Fullscreen toggle
      final expandButton = findById(
        'better_player_material_controls_fullscreen_button',
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
  });
}
