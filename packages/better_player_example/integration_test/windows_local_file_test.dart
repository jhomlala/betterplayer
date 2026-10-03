import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 7: Windows Local File Playback', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Local File Playback\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Local File Playback\n'
        '========================================',
      );
    });

    testWidgets('Play local MP4 file from Windows filesystem', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Trigger local file setup
      final setupFileButton = findById('better_player_e2e_setup_file');
      await scrollAndTap(tester: tester, finder: setupFileButton);

      // 2. Wait for player controls to initialize with local file
      final playPauseButton = findById(
        'better_player_material_controls_play_pause_button',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playPauseButton,
        timeout: const Duration(seconds: 15),
      );

      // 3. Play and pause toggle
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(playPauseButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Seek within local file via keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Verify local file playback status
      final fileStatus = findById('better_player_e2e_file_status');
      await pumpUntilFound(tester: tester, finder: fileStatus);
    });
  });
}
