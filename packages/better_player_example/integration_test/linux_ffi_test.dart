import 'dart:io';

import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 5: Native FFI API', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] STARTING: Native FFI API\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Linux] FINISHED: Native FFI API\n'
        '========================================',
      );
    });

    testWidgets('Execute and verify all native FFI methods', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to Native FFI API Page
      final navigateFfiButton = findById('better_player_e2e_navigate_ffi');
      await scrollAndTap(tester: tester, finder: navigateFfiButton);

      final eventsVerified = findById('better_player_e2e_events_verified');
      await pumpUntilFound(
        tester: tester,
        finder: eventsVerified,
        timeout: const Duration(seconds: 40),
      );

      // 2. Test runtime configuration
      final runtimeConfigButton = findById(
        'better_player_e2e_runtime_config_button',
      );
      await scrollAndTap(tester: tester, finder: runtimeConfigButton);

      final runtimeConfigStatus = findById(
        'better_player_e2e_runtime_config_status',
      );
      await pumpUntilFound(
        tester: tester,
        finder: runtimeConfigStatus,
        timeout: const Duration(seconds: 15),
      );

      // 3. Test keyboard shortcuts callback
      final shortcutStatus = findById(
        'better_player_e2e_keyboard_shortcut_status',
      );
      await pumpUntilFound(
        tester: tester,
        finder: shortcutStatus,
        timeout: const Duration(seconds: 15),
      );

      try {
        await Process.run('import', [
          '-window',
          'root',
          'linux_ffi_page.png',
        ]);
      } catch (_) {}

      // 4. Navigate back to Home
      final navigatorState = tester.state<NavigatorState>(
        find.byType(Navigator),
      );
      navigatorState.pop();
      await tester.pumpAndSettle();

      final title = findById('better_player_e2e_app_bar_title');
      await pumpUntilFound(tester: tester, finder: title);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
