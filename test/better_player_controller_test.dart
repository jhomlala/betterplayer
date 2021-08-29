import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'better_player_mock_controller.dart';
import 'better_player_test_utils.dart';
import 'mock_method_channel.dart';
import 'mock_video_player_controller.dart';

MockMethodChannel? mockMethodChannel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    "BetterPlayerController tests",
    () {
      setUpAll(() {
        mockMethodChannel = MockMethodChannel();
      });
      test("Create controller without data source", () {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(const BetterPlayerConfiguration());
        expect(betterPlayerMockController.betterPlayerDataSource, null);
        expect(betterPlayerMockController.videoPlayerController, null);
      });

      test("Setup data source in controller", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(const BetterPlayerConfiguration());
        await betterPlayerMockController.setupDataSource(
            BetterPlayerDataSource.network(
                BetterPlayerTestUtils.forBiggerBlazesUrl));
        expect(betterPlayerMockController.betterPlayerDataSource != null, true);
        expect(betterPlayerMockController.videoPlayerController != null, true);
      });

      test(
        "Play should change isPlaying flag",
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerController(
            const BetterPlayerConfiguration(),
            betterPlayerDataSource: BetterPlayerDataSource.network(
                BetterPlayerTestUtils.forBiggerBlazesUrl),
          );
          betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
        },
      );

      test(
        "Pause should change isPlaying flag",
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerController(
            const BetterPlayerConfiguration(),
            betterPlayerDataSource: BetterPlayerDataSource.network(
                BetterPlayerTestUtils.forBiggerBlazesUrl),
          );
          betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
          betterPlayerController.pause();
          expect(betterPlayerController.isPlaying(), false);
        },
      );

      test("Full screen and auto play should work together", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(
          const BetterPlayerConfiguration(
              fullScreenByDefault: true, autoPlay: true),
        );
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
              BetterPlayerTestUtils.forBiggerBlazesUrl),
        );
        expect(betterPlayerMockController.isFullScreen, true);
        expect(betterPlayerMockController.isPlaying(), true);
      });

      test("exitFullScreen should exit full screen", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(
          const BetterPlayerConfiguration(
              fullScreenByDefault: true, autoPlay: true),
        );
        await betterPlayerMockController.setupDataSource(
            BetterPlayerDataSource.network(
                BetterPlayerTestUtils.forBiggerBlazesUrl));
        expect(betterPlayerMockController.isFullScreen, true);
        betterPlayerMockController.exitFullScreen();
        expect(betterPlayerMockController.isFullScreen, false);
      });

      test("enterFullScreen should enter full screen", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
              BetterPlayerTestUtils.forBiggerBlazesUrl),
        );
        expect(betterPlayerMockController.isFullScreen, false);
        betterPlayerMockController.enterFullScreen();
        expect(betterPlayerMockController.isFullScreen, true);
      });

      test("toggleFullScreen should change full screen state", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
              BetterPlayerTestUtils.forBiggerBlazesUrl),
        );

        expect(betterPlayerMockController.isFullScreen, false);
        betterPlayerMockController.toggleFullScreen();
        expect(betterPlayerMockController.isFullScreen, true);
        betterPlayerMockController.toggleFullScreen();
        expect(betterPlayerMockController.isFullScreen, false);
      });

      test("setLooping changes looping state", () async {
        final mockVideoPlayerController = MockVideoPlayerController();
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        mockVideoPlayerController
            .setNetworkDataSource(BetterPlayerTestUtils.bugBuckBunnyVideoUrl);

        betterPlayerMockController.videoPlayerController =
            mockVideoPlayerController;
        expect(mockVideoPlayerController.isLoopingState, false);
        betterPlayerMockController.setLooping(true);
        expect(mockVideoPlayerController.isLoopingState, true);
        betterPlayerMockController.setLooping(false);
        expect(mockVideoPlayerController.isLoopingState, false);
      });

      test("isBuffering returns correct value", () async {
        final mockVideoPlayerController =
            BetterPlayerTestUtils.setupMockVideoPlayerControler();
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
          controller: mockVideoPlayerController,
        );
        expect(betterPlayerMockController.isBuffering(), false);
        mockVideoPlayerController.setBuffering(true);
        expect(betterPlayerMockController.isBuffering(), true);
        mockVideoPlayerController.setBuffering(false);
        expect(betterPlayerMockController.isBuffering(), false);
      });
    },
  );
}
