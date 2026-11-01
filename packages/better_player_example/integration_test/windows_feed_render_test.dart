import 'dart:io';

import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 8: Windows Pooled Feed Render Flow', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Pooled Feed Render Flow\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Pooled Feed Render Flow\n'
        '========================================',
      );
    });

    testWidgets('Verify pooled feed rendering and preloading on Windows', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to Feed Render Page
      final navigateFeedButton = findById(
        'better_player_e2e_navigate_feed_render',
      );
      await scrollAndTap(tester: tester, finder: navigateFeedButton);

      // 2. Wait for first video to start playing
      final playing0Status = findById(
        'better_player_e2e_feed_render_status_playing_0',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playing0Status,
        timeout: const Duration(seconds: 60),
      );

      // Wait a moment for frames to decode and render
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      // Capture screenshot if nircmd is available
      try {
        await Process.run('nircmd', [
          'savescreenshot',
          'feed_render_item_0.png',
        ]);
      } catch (_) {}

      // 3. Advance to the pooled, preloaded second item
      final nextButton = findById('better_player_e2e_feed_next_button');
      await pumpUntilFound(tester: tester, finder: nextButton);
      await tester.tap(nextButton);
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Wait for second video to start playing
      final playing1Status = findById(
        'better_player_e2e_feed_render_status_playing_1',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playing1Status,
        timeout: const Duration(seconds: 60),
      );

      // Wait a moment for frames to decode and render
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      // Capture screenshot if nircmd is available
      try {
        await Process.run('nircmd', [
          'savescreenshot',
          'feed_render_item_1.png',
        ]);
      } catch (_) {}
    });
  });
}
