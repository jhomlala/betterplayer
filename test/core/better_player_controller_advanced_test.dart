import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_video_player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

  group('BetterPlayerController advanced tests', () {
    setUp(
      () => {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        ),
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (methodCall) async {
            if (methodCall.method == 'getTemporaryDirectory') {
              return '.';
            }
            return null;
          },
        ),
      },
    );

    test('retryDataSource works', () async {
      final mock = MockVideoPlayerController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );
      await controller.setupDataSource(BetterPlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      ));

      // Simulate error
      mock.value = mock.value.copyWith(errorDescription: 'Error');
      controller.videoPlayerController!.notifyListeners();

      await controller.retryDataSource();
      expect(controller.videoPlayerController != null, true);
    });

    test('preCache and stopPreCache don\'t crash', () async {
      final dataSource = BetterPlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      );
      await BetterPlayerController(const BetterPlayerConfiguration())
          .preCache(dataSource);
      await BetterPlayerController(const BetterPlayerConfiguration())
          .stopPreCache(dataSource);
      await BetterPlayerController(const BetterPlayerConfiguration())
          .clearCache();
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

      final audioTrack = BetterPlayerAsmsAudioTrack(label: 'Test');
      controller.setAudioTrack(audioTrack);
      expect(controller.betterPlayerAsmsAudioTrack, null);
    });

    test('setupDataSource with asset', () async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
      );
      await controller.setupDataSource(
        BetterPlayerDataSource.file('test/video.mp4'),
      );
      expect(controller.betterPlayerDataSource != null, true);
    });

    test('setupDataSource with memory', () async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
      );
      await controller.setupDataSource(
        BetterPlayerDataSource.memory([1, 2, 3]),
      );
      expect(controller.betterPlayerDataSource != null, true);
    });
  });
}
