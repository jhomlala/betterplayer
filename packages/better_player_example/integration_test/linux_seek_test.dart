import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 10: Accurate Video Seeking', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] STARTING: Accurate Video Seeking\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] FINISHED: Accurate Video Seeking\n'
        '========================================',
      );
    });

    testWidgets('Verify accurate seeking and position updates on Linux', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to Seek E2E Page
      final navigateSeekButton = findById('better_player_e2e_navigate_seek');
      await scrollAndTap(tester: tester, finder: navigateSeekButton);

      // 2. Wait for player initialization
      final initializedStatus = findById('better_player_e2e_seek_initialized');
      await pumpUntilFound(
        tester: tester,
        finder: initializedStatus,
        timeout: const Duration(seconds: 40),
      );

      // 3. Tap Seek 10s button
      final seek10sButton = findById('better_player_e2e_seek_10s_button');
      await tapWhenReady(
        tester: tester,
        finder: seek10sButton,
      );

      // 4. Wait for seek verified status (position >= 8s)
      final seek10sVerified = findById('better_player_e2e_seek_10s_verified');
      await pumpUntilFound(
        tester: tester,
        finder: seek10sVerified,
        timeout: const Duration(seconds: 30),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
