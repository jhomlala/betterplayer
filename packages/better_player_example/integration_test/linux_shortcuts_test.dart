import 'dart:ui';

import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 6: Linux Desktop Keyboard & Pointer Controls', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] STARTING: Desktop Shortcuts & Mouse\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] FINISHED: Desktop Shortcuts & Mouse\n'
        '========================================',
      );
    });

    testWidgets('Linux desktop keyboard shortcuts and mouse interactions', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

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

      // 1. Focus player by tapping play/pause
      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Space key: play/pause toggle
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 500));

      // 3. 'K' key: alternative play/pause (YouTube convention)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Arrow keys: seek forward/backward
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 500));

      // 5. 'J' and 'L' keys: 10s seek
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump(const Duration(milliseconds: 500));

      // 6. Up/Down arrow keys: volume adjust
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 500));

      // 7. 'M' key: mute toggle
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump(const Duration(milliseconds: 500));

      // 8. Mouse hover over video area to trigger desktop controls overlay
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      final videoCenter = tester.getCenter(playPauseButton);
      await gesture.moveTo(videoCenter);
      await tester.pump(const Duration(milliseconds: 300));

      // Move away to allow auto-hide timer to start
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 300));

      expect(mp4Initialized, findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
