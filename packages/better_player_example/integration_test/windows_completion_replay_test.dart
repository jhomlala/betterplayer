import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 9: Video Completion & Replay', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Video Completion & Replay\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Video Completion & Replay\n'
        '========================================',
      );
    });

    testWidgets('Natural video completion and replay restart', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final playPauseButton = findById(
        'better_player_material_controls_play_pause_button',
      );
      await pumpUntilFound(
        tester: tester,
        finder: playPauseButton,
        timeout: const Duration(seconds: 30),
      );

      // Seek near end to trigger EOF and completion
      final seekToEndButton = findById('better_player_e2e_seek_to_end_button');
      await scrollAndTap(tester: tester, finder: seekToEndButton);

      // Wait for video completion
      final finishedStatus = findById('better_player_e2e_finished_status');
      await pumpUntilFound(
        tester: tester,
        finder: finishedStatus,
        timeout: const Duration(seconds: 30),
      );

      // Tap replay button in controls
      await tapWhenReady(
        tester: tester,
        finder: playPauseButton,
        timeout: const Duration(seconds: 15),
      );

      // Wait for replay status
      final replayedStatus = findById('better_player_e2e_replayed_status');
      await pumpUntilFound(
        tester: tester,
        finder: replayedStatus,
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
