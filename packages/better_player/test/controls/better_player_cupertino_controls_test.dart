import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  late BetterPlayerMockController mockController;

  setUp(() async {
    final mockMethodChannel = MockMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        );

    mockController = BetterPlayerTestUtils.setupBetterPlayerMockController(
      controller: MockPlayerEngineController(),
    );
    await mockController.setupDataSource(
      PlayerDataSource.network(BetterPlayerTestUtils.forBiggerBlazesUrl),
    );
  });

  Widget wrapWidget(Widget widget, {Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false, brightness: brightness),
      home: Scaffold(
        body: widget,
      ),
    );
  }

  testWidgets(
    'Cupertino controls show CupertinoActionSheet for overflow menu on Android when theme is set to cupertino',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controlsConfiguration = PlayerControlsConfiguration(
        playerTheme: PlayerTheme.cupertino,
        enablePlaybackSpeed: true,
      );
      mockController = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
        configuration: PlayerConfiguration(
          controlsConfiguration: controlsConfiguration,
        )
      );
      await mockController.setupDataSource(
        PlayerDataSource.network(BetterPlayerTestUtils.forBiggerBlazesUrl),
      );

      await tester.pumpWidget(
        wrapWidget(
          BetterPlayer(
            controller: mockController,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 300));
      mockController.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();
      
      final moreButton = find.byIcon(controlsConfiguration.overflowMenuIcon);
      expect(moreButton, findsOneWidget);

      final gestureDetector = tester.widget<GestureDetector>(find.ancestor(of: moreButton, matching: find.byType(GestureDetector)).first);
      gestureDetector.onTap!();
      await tester.pumpAndSettle();

      debugDumpApp();
      // Check if CupertinoActionSheet is displayed instead of Material bottom sheet
      expect(find.byType(CupertinoActionSheet), findsOneWidget);

      // Check if text is present inside a CupertinoActionSheetAction
      expect(
        find.descendant(
          of: find.byType(CupertinoActionSheetAction),
          matching: find.text(mockController.translations.overflowMenuPlaybackSpeed),
        ),
        findsOneWidget,
      );
      
      // Check for Cancel button
      expect(
        find.descendant(
          of: find.byType(CupertinoActionSheetAction),
          matching: find.text('Cancel'),
        ),
        findsOneWidget,
      );
    },
  );
}
