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
        '  [E2E macOS] STARTING: Native FFI API\n'
        '========================================',
      );
    });
    tearDownAll(() {
      debugPrint(
        '========================================\n'
        '  [E2E macOS] FINISHED: Native FFI API\n'
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
        final button = findById('ffi_test_button_$method');
        await scrollAndTap(tester: tester, finder: button);

        final statusFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.identifier == 'ffi_test_status_$method',
        );
        await pumpUntilFound(
          tester: tester,
          finder: statusFinder,
          timeout: const Duration(seconds: 15),
        );

        // Verify that the status text is success=true
        final textWidgetFinder = find.descendant(
          of: statusFinder,
          matching: find.byType(Text),
        );
        expect(textWidgetFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textWidgetFinder);
        expect(
          textWidget.data,
          'success=true',
          reason: 'FFI method $method failed to execute successfully',
        );
      }
    });
  });
}
