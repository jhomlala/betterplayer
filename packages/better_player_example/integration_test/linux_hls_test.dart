import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 2: HLS Streaming', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] STARTING: HLS Streaming\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] FINISHED: HLS Streaming\n'
        '========================================',
      );
    });

    testWidgets('Linux HLS streaming and track selection test', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Setup HLS Data Source
      final setupHlsButton = findById('better_player_e2e_setup_hls');
      await scrollAndTap(tester: tester, finder: setupHlsButton);

      // 2. Wait for HLS initialization
      final hlsInitialized = findById('better_player_e2e_hls_initialized');
      await pumpUntilFound(
        tester: tester,
        finder: hlsInitialized,
        timeout: const Duration(seconds: 45),
      );

      // 3. Wait for video controls
      final playPauseButton = findById(
        'better_player_material_controls_play_pause_button',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playPauseButton,
        timeout: const Duration(seconds: 15),
      );

      // 4. Play / Pause toggle
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Seek within HLS stream via keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 500));

      // 6. Test Track / Quality Selection on HLS
      final moreButton = findById(
        'better_player_material_controls_more_button',
      );
      if (moreButton.evaluate().isNotEmpty) {
        await tapWhenReady(tester: tester, finder: moreButton);

        final qualityMenu = findById('better_player_overflow_menu_quality');
        if (qualityMenu.evaluate().isNotEmpty) {
          await tapWhenReady(tester: tester, finder: qualityMenu);

          // Select first available resolution variant
          final qualityItem = find.byWidgetPredicate(
            (w) =>
                w.runtimeType.toString().contains('PopupMenuItem') ||
                w.runtimeType.toString().contains('_MenuItem'),
          );
          if (qualityItem.evaluate().isNotEmpty) {
            await tester.tap(qualityItem.first, warnIfMissed: false);
            await waitModalClosed(tester: tester);
          } else {
            // Dismiss menu if no items
            await tester.tapAt(const Offset(10, 10));
            await waitModalClosed(tester: tester);
          }
        } else {
          // Dismiss overflow menu
          await tester.tapAt(const Offset(10, 10));
          await waitModalClosed(tester: tester);
        }
      }

      // 7. Test Audio Track Selection if available
      if (moreButton.evaluate().isNotEmpty) {
        await tapWhenReady(tester: tester, finder: moreButton);

        final audioMenu = findById('better_player_overflow_menu_audio');
        if (audioMenu.evaluate().isNotEmpty) {
          await tapWhenReady(tester: tester, finder: audioMenu);
          await waitModalClosed(tester: tester);
        } else {
          await tester.tapAt(const Offset(10, 10));
          await waitModalClosed(tester: tester);
        }
      }

      // 8. Verify HLS playback state remains valid
      expect(hlsInitialized, findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
