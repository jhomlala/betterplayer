import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class BetterPlayerMockController extends BetterPlayerController {
  BetterPlayerMockController(
      BetterPlayerConfiguration betterPlayerConfiguration)
      : super(betterPlayerConfiguration);
}

const MethodChannel channel = MethodChannel("better_player_channel");
const MethodChannel eventChannel =
    MethodChannel("better_player_channel/videoEvents1");
const String bugBuckBunnyVideoUrl =
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
const String forBiggerBlazesUrl =
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Controller tests", () {
    setUpAll(() {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == "create") {
          return {"textureId": 1};
        }
        if (methodCall.method == "setDataSource") {
          return null;
        }
        return Map<String, String>();
      });
      eventChannel.setMockMethodCallHandler((MethodCall methodCall) async {
        print("CALLED METHOD2:" + methodCall.toString());
        defaultBinaryMessenger.handlePlatformMessage(
            "better_player_channel/videoEvents1",
            const StandardMethodCodec().encodeSuccessEnvelope({
              "event": "initialized",
              "height": 720.0,
              "width:": 1280.0,
              "duration": 100
            }),
            (ByteData data) {});
      });
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
      await betterPlayerMockController
          .setupDataSource(BetterPlayerDataSource.network(forBiggerBlazesUrl));
      expect(betterPlayerMockController.betterPlayerDataSource != null, true);
      expect(betterPlayerMockController.videoPlayerController != null, true);
    });

    test("BetterPlayerController - full screen and auto play should work",
        () async {
      BetterPlayerMockController betterPlayerMockController =
          BetterPlayerMockController(BetterPlayerConfiguration(
              fullScreenByDefault: true, autoPlay: true));
      await betterPlayerMockController
          .setupDataSource(BetterPlayerDataSource.network(forBiggerBlazesUrl));
      expect(betterPlayerMockController.isFullScreen, true);
      expect(betterPlayerMockController.isPlaying(), true);
    });
  });
}
