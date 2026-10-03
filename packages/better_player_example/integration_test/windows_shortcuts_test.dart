import 'dart:ui';

import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 6: Windows Desktop Keyboard & Pointer Controls', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Desktop Shortcuts & Mouse\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Desktop Shortcuts & Mouse\n'
        '========================================',
      );
    });

    testWidgets('Windows desktop keyboard shortcuts and mouse interactions', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      final playPauseButton = findById(
        'better_player_material_controls_play_pause_button',
      );
      await pumpUntilFound(tester: tester, finder: playPauseButton);

      // 1. Focus player by tapping play/pause
      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Space key: toggle play / pause
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 500));

      // 3. 'K' key: toggle play / pause
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Arrow keys: seek forward and backward
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Arrow Up / Down keys: volume adjustments
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 500));

      final shortcutStatus = findById(
        'better_player_e2e_keyboard_shortcut_status',
      );
      await pumpUntilFound(
        tester: tester,
        finder: shortcutStatus,
        timeout: const Duration(seconds: 10),
      );

      // 6. 'M' key: mute and unmute
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump(const Duration(milliseconds: 500));

      // 7. Mouse hover simulation
      final progressBar = findById('better_player_material_progress_bar');
      if (progressBar.evaluate().isNotEmpty) {
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(progressBar.first));
        await tester.pump(const Duration(milliseconds: 300));
      }
    });
  });
}
