import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_web_controls.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      home: Scaffold(
        body: widget,
      ),
    );
  }

    testWidgets(
    'BetterPlayerWebControls is rendered when theme is web',
    (tester) async {
      final mockMethodChannel = MockMethodChannel();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            mockMethodChannel.channel,
            mockMethodChannel.handle,
          );
      const controlsConfiguration = PlayerControlsConfiguration(
        playerTheme: PlayerTheme.web,
      );
      final customMockController = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
        configuration: const PlayerConfiguration(
          controlsConfiguration: controlsConfiguration,
        ),
      );
      await customMockController.setupDataSource(
        PlayerDataSource.network(BetterPlayerTestUtils.forBiggerBlazesUrl),
      );
      await tester.pumpWidget(
        wrapWidget(
          BetterPlayer(
            controller: customMockController,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      customMockController.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      expect(find.byType(BetterPlayerWebControls), findsOneWidget);
    },
  );
}
