import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 2: HLS Streaming', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: HLS Streaming\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: HLS Streaming\n'
        '========================================',
      );
    });

    testWidgets('Windows HLS streaming and track selection test', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Setup HLS Data Source
      final setupHlsButton = findById('better_player_e2e_setup_hls');
      await scrollAndTap(tester: tester, finder: setupHlsButton);

      // 2. Wait for video controls
      final playPauseButton = findById(
        'better_player_cupertino_controls_play_pause_button',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playPauseButton,
        timeout: const Duration(seconds: 30),
      );
      try {
        await tester.ensureVisible(playPauseButton.first);
        await tester.pump(const Duration(milliseconds: 200));
      } catch (_) {}

      // 3. Play/Pause toggle
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Skip testing
      final skipForward = findById(
        'better_player_cupertino_controls_skip_forward_button',
      );
      if (skipForward.evaluate().isNotEmpty) {
        await tester.tap(skipForward.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
      }

      final skipBack = findById(
        'better_player_cupertino_controls_skip_back_button',
      );
      if (skipBack.evaluate().isNotEmpty) {
        await tester.tap(skipBack.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
      }

      // 5. Open Overflow Menu
      final moreButton = findById(
        'better_player_cupertino_controls_more_button',
      );
      await tapWhenReady(tester: tester, finder: moreButton);

      // 6. Quality Selection
      final qualityMenu = findById('better_player_overflow_menu_quality');
      await tapWhenReady(tester: tester, finder: qualityMenu);

      final qualityFirstVariant = findById(
        'better_player_overflow_menu_quality_track_0',
      );
      if (qualityFirstVariant.evaluate().isNotEmpty) {
        await tapWhenReady(tester: tester, finder: qualityFirstVariant);
        await waitModalClosed(tester: tester);
      } else {
        final qualityAuto = findById(
          'better_player_overflow_menu_quality_auto',
        );
        await tapWhenReady(tester: tester, finder: qualityAuto);
        await waitModalClosed(tester: tester);
      }

      // 7. Audio Track Selection
      await tapWhenReady(tester: tester, finder: moreButton);
      final audioMenu = findById('better_player_overflow_menu_audio');
      if (audioMenu.evaluate().isNotEmpty) {
        await tapWhenReady(tester: tester, finder: audioMenu);
        final firstAudioTrack = findById(
          'better_player_overflow_menu_audio_track_0',
        );
        if (firstAudioTrack.evaluate().isNotEmpty) {
          await tapWhenReady(tester: tester, finder: firstAudioTrack);
        }
        await waitModalClosed(tester: tester);
      } else {
        await tester.tapAt(const Offset(20, 20));
        await waitModalClosed(tester: tester);
      }

      // 8. Dynamic Configuration Updates
      final updateConfigButton = findById('better_player_e2e_update_config');
      await scrollAndTap(tester: tester, finder: updateConfigButton);

      final configUpdated = findById('better_player_e2e_config_updated');
      await pumpUntilFound(tester: tester, finder: configUpdated);
      expect(configUpdated, findsOneWidget);

      // 9. Visibility Callback
      final triggerVisibility = findById(
        'better_player_e2e_trigger_visibility',
      );
      await scrollAndTap(tester: tester, finder: triggerVisibility);

      final visibilityFired = findById(
        'better_player_e2e_visibility_callback_fired',
      );
      await pumpUntilFound(tester: tester, finder: visibilityFired);
      expect(visibilityFired, findsOneWidget);
    });
  });
}
