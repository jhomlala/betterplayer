import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';

void main() {
  setUpAll(() {
    BetterPlayerTestUtils.setupMockPlatform();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('BetterPlayerWithControls tests', () {
    testWidgets('Renders properly with controller', (
      tester,
    ) async {
      final mockVideoPlayerController =
          BetterPlayerTestUtils.setupMockPlayerEngineController();
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
        playerEngineController: mockVideoPlayerController,
      );

      await controller.setupDataSource(
        PlayerDataSource.network('url'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
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

    testWidgets('Renders placeholder when provided', (
      tester,
    ) async {
      final mockVideoPlayerController =
          BetterPlayerTestUtils.setupMockPlayerEngineController();
      final placeholder = Container(key: const Key('placeholder'));
      final controller = BetterPlayerMockController(
        PlayerConfiguration(
          placeholder: placeholder,
          showPlaceholderUntilPlay: true,
        ),
        playerEngineController: mockVideoPlayerController,
      );

      await controller.setupDataSource(
        PlayerDataSource.network('url'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
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

    testWidgets('Updates aspect ratio when video size changes', (
      tester,
    ) async {
      final mockVideoPlayerController =
          BetterPlayerTestUtils.setupMockPlayerEngineController();
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
        playerEngineController: mockVideoPlayerController,
      );

      await controller.setupDataSource(
        PlayerDataSource.network('url'),
      );

      // Initial size (default mock might have a certain size or null)
      mockVideoPlayerController.value = mockVideoPlayerController.value
          .copyWith(
            size: const Size(1280, 720),
            duration: const Duration(seconds: 1),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: BetterPlayerControllerProvider(
            controller: controller,
            child: BetterPlayerWithControls(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify initial AspectRatio
      final initialAspectRatio = tester
          .widget<AspectRatio>(find.byType(AspectRatio))
          .aspectRatio;
      expect(initialAspectRatio, 1280 / 720);

      // Change video size
      mockVideoPlayerController.value = mockVideoPlayerController.value
          .copyWith(size: const Size(1920, 1080));
      mockVideoPlayerController.notifyListeners();

      await tester.pump();

      // Verify updated AspectRatio
      final updatedAspectRatio = tester
          .widget<AspectRatio>(find.byType(AspectRatio))
          .aspectRatio;
      expect(updatedAspectRatio, 1920 / 1080);

      // Change video size to something different
      mockVideoPlayerController.value = mockVideoPlayerController.value
          .copyWith(size: const Size(720, 1280));
      mockVideoPlayerController.notifyListeners();

      await tester.pump();

      final portraitAspectRatio = tester
          .widget<AspectRatio>(find.byType(AspectRatio))
          .aspectRatio;
      expect(portraitAspectRatio, 720 / 1280);
    });

    testWidgets('Updates video fit widget when video size changes', (
      tester,
    ) async {
      final mockVideoPlayerController =
          BetterPlayerTestUtils.setupMockPlayerEngineController();
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
        playerEngineController: mockVideoPlayerController,
      );

      await controller.setupDataSource(
        PlayerDataSource.network('url'),
      );

      mockVideoPlayerController.value = mockVideoPlayerController.value
          .copyWith(
            size: const Size(1280, 720),
            duration: const Duration(seconds: 1),
          );

      // We need to trigger play for the fit widget to show (it depends on _started)
      controller.play();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: BetterPlayerControllerProvider(
            controller: controller,
            child: BetterPlayerWithControls(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify initial SizedBox size inside FittedBox
      var sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FittedBox),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 1280);
      expect(sizedBox.height, 720);

      // Change video size
      mockVideoPlayerController.value = mockVideoPlayerController.value
          .copyWith(size: const Size(1920, 1080));
      mockVideoPlayerController.notifyListeners();

      await tester.pump();

      // Verify updated SizedBox size
      sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FittedBox),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 1920);
      expect(sizedBox.height, 1080);
    });
  });
}
