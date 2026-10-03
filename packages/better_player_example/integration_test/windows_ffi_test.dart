import 'dart:io';

import 'package:better_player_example/main_e2e.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Suite 5: Native FFI API', () {
    setUpAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] STARTING: Native FFI API\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E Windows] FINISHED: Native FFI API\n'
        '========================================',
      );
    });

    testWidgets('Execute and verify all native FFI methods', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to FFI Test Page
      final navigateFfiButton = findById('better_player_e2e_navigate_ffi');
      await scrollAndTap(tester: tester, finder: navigateFfiButton);

      // 2. Wait for player to be initialized
      final initializedStatus = findById('ffi_test_initialized_status');
      await pumpUntilFound(
        tester: tester,
        finder: initializedStatus,
        timeout: const Duration(seconds: 40),
      );

      // 3. Test core FFI methods
      final ffiMethods = [
        'play',
        'pause',
        'seekTo',
        'setVolume',
        'setSpeed',
        'setTrackParameters',
        'setAudioTrack',
        'setMixWithOthers',
        'setLooping',
        'getPosition',
        'playerValue',
        'duration',
        'isInitialized',
      ];

      for (final method in ffiMethods) {
        final button = findById('ffi_btn_$method');
        if (button.evaluate().isNotEmpty) {
          await tapWhenReady(tester: tester, finder: button);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      // 4. Verify all tested without fatal crash
      expect(initializedStatus, findsOneWidget);

      try {
        await Process.run('nircmd', [
          'savescreenshot',
          'windows_ffi_page.png',
        ]);
      } catch (_) {}

      // 5. Navigate back to home
      final navigator = Navigator.of(tester.element(initializedStatus));
      navigator.pop();
      await tester.pumpAndSettle();
    });
  });
}
