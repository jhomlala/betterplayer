import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_player_engine_controller.dart';

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
      final mock = MockPlayerEngineController();
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
      mock.notifyListeners();

      await controller.retryDataSource();
      expect(controller.isEngineReady, true);
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
      final mock = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );

      final isSupported = await controller.isPictureInPictureSupported();
      expect(isSupported, false); // Default mock returns false
    });

    test('setAudioTrack with null language', () {
      final mock = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );

      final audioTrack = PlayerAsmsAudioTrack(label: 'Test');
      controller.setAudioTrack(audioTrack);
      expect(controller.betterPlayerAsmsAudioTrack, null);
    });

    test('setupDataSource with asset', () async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
      );
      await controller.setupDataSource(
        PlayerDataSource.file('test/video.mp4'),
      );
      expect(controller.betterPlayerDataSource != null, true);
    });

    test('setupDataSource with memory', () async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
      );
      await controller.setupDataSource(
        PlayerDataSource.memory([1, 2, 3]),
      );
      expect(controller.betterPlayerDataSource != null, true);
    });

    test(
      'setupDataSource controller event is posted after setup completes',
      () async {
        final mock = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mock,
            );

        final events = <PlayerControllerEvent>[];
        controller.controllerEventStream.listen(events.add);

        await controller.setupDataSource(
          PlayerDataSource.network('https://example.com/test.mp4'),
        );

        await Future.microtask(() {});

        // Verify that setupDataSource controller event was posted
        expect(events.contains(PlayerControllerEvent.setupDataSource), true);
      },
    );

    test(
      'setResolution emits changedResolution event exactly once and setupDataSource after',
      () async {
        final mock = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mock,
            );

        await controller.setupDataSource(
          PlayerDataSource.network('https://example.com/video1.mp4'),
        );

        var changedResolutionCount = 0;
        controller.addEventsListener((event) {
          if (event.betterPlayerEventType ==
              PlayerEventType.changedResolution) {
            changedResolutionCount++;
          }
        });

        final controllerEvents = <PlayerControllerEvent>[];
        final subscription = controller.controllerEventStream.listen(
          controllerEvents.add,
        );

        await controller.setResolution('https://example.com/video2.mp4');

        await Future.microtask(() {});

        expect(changedResolutionCount, 1);
        expect(controllerEvents.isNotEmpty, true);
        expect(controllerEvents.last, PlayerControllerEvent.setupDataSource);

        await subscription.cancel();
      },
    );
  });
}
