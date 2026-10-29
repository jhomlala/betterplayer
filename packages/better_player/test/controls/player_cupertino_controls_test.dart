import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/player_cupertino_controls.dart';
import 'package:better_player/src/core/player_with_controls.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_better_player_platform.dart';
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

      const controlsConfiguration = PlayerControlsConfiguration(
        playerTheme: PlayerTheme.cupertino,
      );
      mockController = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
        configuration: const PlayerConfiguration(
          controlsConfiguration: controlsConfiguration,
        ),
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

      final moreButton = find.byIcon(
        mockController.betterPlayerControlsConfiguration.overflowMenuIcon,
      );
      expect(moreButton, findsOneWidget);

      await tester.tap(moreButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Check if CupertinoActionSheet is displayed instead of Material bottom sheet
      expect(find.byType(CupertinoActionSheet), findsOneWidget);

      // Check if text is present inside a CupertinoActionSheetAction
      expect(
        find.descendant(
          of: find.byType(CupertinoActionSheetAction),
          matching: find.text(
            mockController.translations.overflowMenuPlaybackSpeed,
          ),
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
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'PlayerCupertinoControls hides controls when controlsEnabled is false and restores when true',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const controlsConfiguration = PlayerControlsConfiguration(
        playerTheme: PlayerTheme.cupertino,
      );
      final mockEngine = MockPlayerEngineController();
      mockEngine.setDuration(const Duration(seconds: 100));
      mockController = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockEngine,
        configuration: const PlayerConfiguration(
          controlsConfiguration: controlsConfiguration,
        ),
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
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      final playIcon =
          mockController.betterPlayerControlsConfiguration.playIcon;
      expect(find.byIcon(playIcon), findsOneWidget);

      mockController.setControlsEnabled(false);
      await tester.pumpAndSettle();

      expect(find.byIcon(playIcon), findsNothing);

      mockController.setControlsEnabled(true);
      await tester.pumpAndSettle();

      expect(find.byIcon(playIcon), findsOneWidget);
    },
  );

  testWidgets(
    'PlayerCupertinoControls disposes safely',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerControllerProvider(
              controller: mockController,
              child: PlayerCupertinoControls(
                controlsConfiguration: const PlayerControlsConfiguration(),
                onControlsVisibilityChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Cupertino controls show AirPlay button and trigger picker on tap',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.cupertino,
            airPlayIcon: CupertinoIcons.tv,
          ),
        ),
      );
      await controller.setupDataSource(
        PlayerDataSource.network(BetterPlayerTestUtils.forBiggerBlazesUrl),
      );

      await tester.pumpWidget(
        wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      controller.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      final airPlayFinder = find.byIcon(CupertinoIcons.tv);
      expect(airPlayFinder, findsOneWidget);

      await tester.tap(airPlayFinder);
      await tester.pump();
      expect(mockPlatform.showExternalPlaybackPickerCalls.length, 1);
    },
  );
}
