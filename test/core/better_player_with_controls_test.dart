import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('BetterPlayerWithControls tests', () {
    testWidgets('Renders properly with controller',
        (WidgetTester tester) async {
      final mockVideoPlayerController =
          BetterPlayerTestUtils.setupMockVideoPlayerControler();
      final controller = BetterPlayerMockController(
        const BetterPlayerConfiguration(),
      );
      controller.videoPlayerController = mockVideoPlayerController;

      await controller.setupDataSource(
        BetterPlayerDataSource.network('url'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BetterPlayerControllerProvider(
            controller: controller,
            child: BetterPlayerWithControls(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BetterPlayerWithControls), findsOneWidget);
    });

    testWidgets('Renders placeholder when provided',
        (WidgetTester tester) async {
      final mockVideoPlayerController =
          BetterPlayerTestUtils.setupMockVideoPlayerControler();
      final placeholder = Container(key: const Key('placeholder'));
      final controller = BetterPlayerMockController(
        BetterPlayerConfiguration(
          placeholder: placeholder,
          showPlaceholderUntilPlay: true,
        ),
      );
      controller.videoPlayerController = mockVideoPlayerController;

      await controller.setupDataSource(
        BetterPlayerDataSource.network('url'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BetterPlayerControllerProvider(
            controller: controller,
            child: BetterPlayerWithControls(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('placeholder')), findsOneWidget);
    });
  });
}
