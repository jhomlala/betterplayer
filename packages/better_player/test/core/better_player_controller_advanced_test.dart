import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_video_player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

  setUpAll(BetterPlayerTestUtils.setupMockPlatform);

  group('BetterPlayerController advanced tests', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            mockMethodChannel.channel,
            mockMethodChannel.handle,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (methodCall) async {
              if (methodCall.method == 'getTemporaryDirectory') {
                return '.';
              }
              return null;
            },
          );
    });

    test('retryDataSource works', () async {
      final mock = MockVideoPlayerController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );
      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      // Simulate error
      mock.value = mock.value.copyWith(errorDescription: 'Error');
      controller.videoPlayerController!.notifyListeners();

      await controller.retryDataSource();
      expect(controller.videoPlayerController != null, true);
    });

    test("preCache and stopPreCache don't crash", () async {
      final dataSource = PlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      );
      await BetterPlayerController(
        const PlayerConfiguration(),
      ).preCache(
        dataSource,
      );
      await BetterPlayerController(
        const PlayerConfiguration(),
      ).stopPreCache(dataSource);
      await BetterPlayerController(
        const PlayerConfiguration(),
      ).clearCache();
    });

    test('PiP support check', () async {
      final mock = MockVideoPlayerController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );

      final isSupported = await controller.isPictureInPictureSupported();
      expect(isSupported, false); // Default mock returns false
    });

    test('setAudioTrack with null language', () {
      final mock = MockVideoPlayerController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );

      final audioTrack = PlayerAsmsAudioTrack(label: 'Test');
      controller.setAudioTrack(audioTrack);
      expect(controller.betterPlayerAsmsAudioTrack, null);
    });

    test('setupDataSource with asset', () async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
      );
      await controller.setupDataSource(
        PlayerDataSource.file('test/video.mp4'),
      );
      expect(controller.betterPlayerDataSource != null, true);
    });

    test('setupDataSource with memory', () async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
      );
      await controller.setupDataSource(
        PlayerDataSource.memory([1, 2, 3]),
      );
      expect(controller.betterPlayerDataSource != null, true);
    });
  });
}
