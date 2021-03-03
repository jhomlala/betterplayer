import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'better_player_mock_controller.dart';
import 'better_player_test_utils.dart';
import 'mock_method_channel.dart';

MockMethodChannel mockMethodChannel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    "Controller tests",
    () {
      setUpAll(() {
        mockMethodChannel = MockMethodChannel();
      });
      test("BetterPlayerController - create without data source", () {
        BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(BetterPlayerConfiguration());
        expect(betterPlayerMockController.betterPlayerDataSource, null);
        expect(betterPlayerMockController.videoPlayerController, null);
      });

      test("BetterPlayerController - setup data source", () async {
        BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(BetterPlayerConfiguration());
        await betterPlayerMockController.setupDataSource(
            BetterPlayerDataSource.network(
                BetterPlayerTestUtils.forBiggerBlazesUrl));
        expect(betterPlayerMockController.betterPlayerDataSource != null, true);
        expect(betterPlayerMockController.videoPlayerController != null, true);
      });

      test(
        "BetterPlayerController - play should change isPlaying flag",
        () async {
          BetterPlayerController betterPlayerController =
              BetterPlayerController(BetterPlayerConfiguration(),
                  betterPlayerDataSource: BetterPlayerDataSource.network(
                      BetterPlayerTestUtils.forBiggerBlazesUrl));
          betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
        },
      );

      test(
        "BetterPlayerController - pause should change isPlaying flag",
        () async {
          BetterPlayerController betterPlayerController =
              BetterPlayerController(BetterPlayerConfiguration(),
                  betterPlayerDataSource: BetterPlayerDataSource.network(
                      BetterPlayerTestUtils.forBiggerBlazesUrl));
          betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
          betterPlayerController.pause();
          expect(betterPlayerController.isPlaying(), false);
        },
      );

      test("BetterPlayerController - full screen and auto play should work",
          () async {
        BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(BetterPlayerConfiguration(
                fullScreenByDefault: true, autoPlay: true));
        await betterPlayerMockController.setupDataSource(
            BetterPlayerDataSource.network(
                BetterPlayerTestUtils.forBiggerBlazesUrl));
        expect(betterPlayerMockController.isFullScreen, true);
        expect(betterPlayerMockController.isPlaying(), true);
      });
    },
  );
}
