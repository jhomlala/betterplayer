import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'better_player_mock_controller.dart';
import 'better_player_test_utils.dart';
import 'mock_method_channel.dart';
import 'mock_video_player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockMethodChannel mockMethodChannel = MockMethodChannel();

  group(
    "BetterPlayerController tests",
    () {
      setUp(
        () => {
          TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
              .setMockMethodCallHandler(
                  mockMethodChannel.channel, mockMethodChannel.handle)
        },
      );

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
        "play should change isPlaying flag",
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerController.videoPlayerController = videoPlayerController;
          await Future.delayed(const Duration(seconds: 1), () {});
          betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
        },
      );

      test(
        "pause should change isPlaying flag",
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerController.videoPlayerController = videoPlayerController;
          await Future.delayed(const Duration(seconds: 1), () {});
          betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
          betterPlayerController.pause();
          expect(betterPlayerController.isPlaying(), false);
        },
      );

      test(
        "seekTo should change player position",
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          videoPlayerController.setDuration(const Duration(seconds: 100));
          betterPlayerController.videoPlayerController = videoPlayerController;
          betterPlayerController.seekTo(const Duration(seconds: 5));
          Duration? position =
              await betterPlayerController.videoPlayerController!.position;
          expect(position, const Duration(seconds: 5));
          betterPlayerController.seekTo(const Duration(seconds: 30));
          position =
              await betterPlayerController.videoPlayerController!.position;
          expect(position, const Duration(seconds: 30));
        },
      );

      test(
        "seekTo should send event",
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          videoPlayerController.setDuration(const Duration(seconds: 100));
          betterPlayerController.videoPlayerController = videoPlayerController;

          int seekEventCalls = 0;
          int finishEventCalls = 0;
          betterPlayerController.addEventsListener((event) {
            if (event.betterPlayerEventType == BetterPlayerEventType.seekTo) {
              seekEventCalls += 1;
            }
            if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
              finishEventCalls += 1;
            }
          });
          betterPlayerController.seekTo(const Duration(seconds: 5));
          await Future.delayed(const Duration(milliseconds: 100), () {});
          expect(seekEventCalls, 1);
          betterPlayerController.seekTo(const Duration(seconds: 150));
          await Future.delayed(const Duration(milliseconds: 100), () {});
          expect(seekEventCalls, 2);
          expect(finishEventCalls, 1);
        },
      );

      test("full screen and auto play should work", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerMockController(
          const BetterPlayerConfiguration(
              fullScreenByDefault: true, autoPlay: true),
        );
        betterPlayerMockController.videoPlayerController =
            MockVideoPlayerController();
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
              BetterPlayerTestUtils.forBiggerBlazesUrl),
        );
        await Future.delayed(const Duration(seconds: 1), () {});
        expect(betterPlayerMockController.isFullScreen, true);
        expect(betterPlayerMockController.isPlaying(), true);
      });

      test("exitFullScreen should exit full screen", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
          controller: MockVideoPlayerController(),
        );
        expect(betterPlayerMockController.isFullScreen, false);
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

      test("setControlsVisibility updates controlVisiblityStream", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var showCalls = 0;
        var hideCalls = 0;
        betterPlayerMockController.controlsVisibilityStream.listen((event) {
          if (event) {
            showCalls += 1;
          } else {
            hideCalls += 1;
          }
        });
        betterPlayerMockController.setControlsVisibility(false);
        betterPlayerMockController.setControlsVisibility(false);
        betterPlayerMockController.setControlsVisibility(true);
        betterPlayerMockController.setControlsVisibility(true);
        betterPlayerMockController.setControlsVisibility(false);
        await Future.delayed(const Duration(milliseconds: 100), () {});
        expect(hideCalls, 3);
        expect(showCalls, 2);
      });

      test("setControlsEnabled updates values correctly", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var hideCalls = 0;
        betterPlayerMockController.controlsVisibilityStream.listen((event) {
          hideCalls += 1;
        });
        betterPlayerMockController.setControlsEnabled(false);
        betterPlayerMockController.setControlsEnabled(false);
        await Future.delayed(const Duration(milliseconds: 100), () {});
        expect(hideCalls, 2);
        expect(betterPlayerMockController.controlsEnabled, false);
        betterPlayerMockController.setControlsEnabled(true);
        expect(betterPlayerMockController.controlsEnabled, true);
      });

      test("toggleControlsVisibility sends correct events", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var controlsVisibleEventCount = 0;
        var controlsHiddenEventCount = 0;
        betterPlayerMockController.addEventsListener((event) {
          if (event.betterPlayerEventType ==
              BetterPlayerEventType.controlsVisible) {
            controlsVisibleEventCount += 1;
          }
          if (event.betterPlayerEventType ==
              BetterPlayerEventType.controlsHiddenEnd) {
            controlsHiddenEventCount += 1;
          }
        });
        betterPlayerMockController.toggleControlsVisibility(false);
        betterPlayerMockController.toggleControlsVisibility(true);
        betterPlayerMockController.toggleControlsVisibility(true);
        await Future.delayed(const Duration(milliseconds: 100), () {});
        expect(controlsVisibleEventCount, 2);
        expect(controlsHiddenEventCount, 1);
      });

      test("postEvent sends events to listeners", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();

        int firstEventCounter = 0;
        int secondEventCounter = 0;

        betterPlayerMockController.addEventsListener((event) {
          firstEventCounter++;
        });
        betterPlayerMockController.addEventsListener((event) {
          secondEventCounter++;
        });
        betterPlayerMockController
            .postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
        betterPlayerMockController
            .postEvent(BetterPlayerEvent(BetterPlayerEventType.progress));

        betterPlayerMockController
            .postEvent(BetterPlayerEvent(BetterPlayerEventType.pause));
        await Future.delayed(const Duration(milliseconds: 100), () {});
        expect(firstEventCounter, 3);
        expect(secondEventCounter, 3);
      });

      test("addEventsListener update list of event listener", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        betterPlayerMockController.addEventsListener((event) {});
        betterPlayerMockController.addEventsListener((event) {});
        expect(betterPlayerMockController.eventListeners.length, 2);
      });

      void dummyEventListener(BetterPlayerEvent event) {}

      test("removeEventsListener update list of event listener", () async {
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        betterPlayerMockController.addEventsListener(dummyEventListener);
        betterPlayerMockController.addEventsListener((event) {});
        expect(betterPlayerMockController.eventListeners.length, 2);
        betterPlayerMockController.removeEventsListener(dummyEventListener);
        expect(betterPlayerMockController.eventListeners.length, 1);
      });

      test("setVolume changes volume", () async {
        final mockVideoPlayerController = MockVideoPlayerController();
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        mockVideoPlayerController
            .setNetworkDataSource(BetterPlayerTestUtils.bugBuckBunnyVideoUrl);
        betterPlayerMockController.videoPlayerController =
            mockVideoPlayerController;
        betterPlayerMockController.setVolume(1.0);
        expect(mockVideoPlayerController.volume, 1.0);
        betterPlayerMockController.setVolume(0.5);
        expect(mockVideoPlayerController.volume, 0.5);
      });

      test(
        "setVolume should send event",
        () async {
          final BetterPlayerController betterPlayerMockController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerMockController.videoPlayerController =
              videoPlayerController;

          int setVolumeCalls = 0;
          betterPlayerMockController.addEventsListener((event) {
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.setVolume) {
              setVolumeCalls += 1;
            }
          });
          betterPlayerMockController.setVolume(1.0);
          await Future.delayed(const Duration(milliseconds: 100), () {});
          expect(setVolumeCalls, 1);
          betterPlayerMockController.setVolume(1.0);
          await Future.delayed(const Duration(milliseconds: 100), () {});
          expect(setVolumeCalls, 2);
        },
      );

      test("setSpeed changes speed", () async {
        final mockVideoPlayerController = MockVideoPlayerController();
        final BetterPlayerMockController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        mockVideoPlayerController
            .setNetworkDataSource(BetterPlayerTestUtils.bugBuckBunnyVideoUrl);
        betterPlayerMockController.videoPlayerController =
            mockVideoPlayerController;
        betterPlayerMockController.setSpeed(1.1);
        expect(mockVideoPlayerController.speed, 1.1);
        betterPlayerMockController.setSpeed(0.5);
        expect(mockVideoPlayerController.speed, 0.5);
        expect(() => betterPlayerMockController.setSpeed(2.5),
            throwsA(isA<ArgumentError>()));
        expect(mockVideoPlayerController.speed, 0.5);
        expect(() => betterPlayerMockController.setSpeed(0.0),
            throwsA(isA<ArgumentError>()));
        expect(mockVideoPlayerController.speed, 0.5);
      });

      test(
        "setSpeed should send event",
        () async {
          final BetterPlayerController betterPlayerMockController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerMockController.videoPlayerController =
              videoPlayerController;

          int setSpeedCalls = 0;
          betterPlayerMockController.addEventsListener((event) {
            if (event.betterPlayerEventType == BetterPlayerEventType.setSpeed) {
              setSpeedCalls += 1;
            }
          });
          betterPlayerMockController.setSpeed(1.5);
          await Future.delayed(const Duration(milliseconds: 100), () {});
          expect(setSpeedCalls, 1);
          betterPlayerMockController.setSpeed(1.0);
          await Future.delayed(const Duration(milliseconds: 100), () {});
          expect(setSpeedCalls, 2);
        },
      );

      test("isBuffering returns valid value", () async {
        final BetterPlayerController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        final videoPlayerController =
            BetterPlayerTestUtils.setupMockVideoPlayerControler();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;
        videoPlayerController.setBuffering(false);
        expect(betterPlayerMockController.isBuffering(), false);
        videoPlayerController.setBuffering(true);
        expect(betterPlayerMockController.isBuffering(), true);
      });

      test("isLiveStream returns valid value", () async {
        final BetterPlayerController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        expect(() => betterPlayerMockController.isLiveStream(),
            throwsA(isA<StateError>()));
        betterPlayerMockController.setupDataSource(BetterPlayerDataSource(
            BetterPlayerDataSourceType.network,
            BetterPlayerTestUtils.forBiggerBlazesUrl,
            liveStream: true));
        final videoPlayerController =
            BetterPlayerTestUtils.setupMockVideoPlayerControler();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;
        expect(betterPlayerMockController.isLiveStream(), true);
      });

      test("isVideoInitalized returns valid value", () async {
        final BetterPlayerController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        expect(() => betterPlayerMockController.isVideoInitialized(),
            throwsA(isA<StateError>()));
        final videoPlayerController =
            BetterPlayerTestUtils.setupMockVideoPlayerControler();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;
        videoPlayerController.setDuration(const Duration(seconds: 1));
        expect(betterPlayerMockController.isVideoInitialized(), true);
      });

      test("startNextVideoTimer starts next video timer", () async {
        final BetterPlayerController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        int eventCount = 0;
        betterPlayerMockController.nextVideoTimeStream.listen((event) {
          eventCount += 1;
        });
        betterPlayerMockController.startNextVideoTimer();
        await Future.delayed(const Duration(milliseconds: 3000), () {});
        expect(eventCount, 3);
      });
    },
  );
}
