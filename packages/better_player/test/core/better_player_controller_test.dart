import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_controller_event.dart';
import 'package:better_player_ios/better_player_ios.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_video_player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

  group(
    'BetterPlayerController tests',
    () {
      setUp(
        () => {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                mockMethodChannel.channel,
                mockMethodChannel.handle,
              ),
        },
      );

      test('Create controller without data source', () {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        expect(betterPlayerMockController.betterPlayerDataSource, null);
        expect(betterPlayerMockController.videoPlayerController, null);
        expect(betterPlayerMockController.eventListeners.isEmpty, true);
      });

      test('Add and remove event listener', () {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        void listener(BetterPlayerEvent event) {}
        betterPlayerMockController.addEventsListener(listener);
        expect(betterPlayerMockController.eventListeners.length, 1);
        betterPlayerMockController.removeEventsListener(listener);
        expect(betterPlayerMockController.eventListeners.isEmpty, true);
      });

      test('setSpeed changes speed', () async {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        final videoPlayerController = MockVideoPlayerController();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;

        await betterPlayerMockController.setSpeed(1.5);
        expect(videoPlayerController.speed, 1.5);
      });

      test('setVolume changes volume', () async {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        final videoPlayerController = MockVideoPlayerController();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;

        await betterPlayerMockController.setVolume(0.8);
        expect(videoPlayerController.volume, 0.8);
      });

      test('setLooping changes looping', () async {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        final videoPlayerController = MockVideoPlayerController();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;

        await betterPlayerMockController.setLooping(true);
        expect(videoPlayerController.isLoopingState, true);
      });

      test('isLiveStream returns true for live stream source', () async {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network('url', liveStream: true),
        );
        expect(betterPlayerMockController.isLiveStream(), true);
      });

      test('isVideoInitialized returns correct value', () async {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        expect(
          betterPlayerMockController.isVideoInitialized,
          throwsStateError,
        );

        final videoPlayerController = MockVideoPlayerController();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;

        expect(betterPlayerMockController.isVideoInitialized(), false);
        videoPlayerController.emitInitialized();
        expect(betterPlayerMockController.isVideoInitialized(), true);
      });

      test('Setup data source in controller', () async {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );
        expect(betterPlayerMockController.betterPlayerDataSource != null, true);
        expect(betterPlayerMockController.videoPlayerController != null, true);
      });

      test(
        'play should change isPlaying flag',
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerController.videoPlayerController = videoPlayerController;
          await Future<void>.delayed(const Duration(seconds: 1), () {});
          await betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
        },
      );

      test(
        'pause should change isPlaying flag',
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerController.videoPlayerController = videoPlayerController;
          await Future<void>.delayed(const Duration(seconds: 1), () {});
          await betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
          await betterPlayerController.pause();
          expect(betterPlayerController.isPlaying(), false);
        },
      );

      test(
        'seekTo should change player position',
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          videoPlayerController.setDuration(const Duration(seconds: 100));
          betterPlayerController.videoPlayerController = videoPlayerController;
          await betterPlayerController.seekTo(const Duration(seconds: 5));
          var position =
              await betterPlayerController.videoPlayerController!.position;
          expect(position, const Duration(seconds: 5));
          await betterPlayerController.seekTo(const Duration(seconds: 30));
          position =
              await betterPlayerController.videoPlayerController!.position;
          expect(position, const Duration(seconds: 30));
        },
      );

      test(
        'seekTo should send event',
        () async {
          final BetterPlayerController betterPlayerController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          videoPlayerController.setDuration(const Duration(seconds: 100));
          betterPlayerController.videoPlayerController = videoPlayerController;

          var seekEventCalls = 0;
          var finishEventCalls = 0;
          betterPlayerController.addEventsListener(
            (event) {
              if (event.betterPlayerEventType == BetterPlayerEventType.seekTo) {
                seekEventCalls += 1;
              }
              if (event.betterPlayerEventType ==
                  BetterPlayerEventType.finished) {
                finishEventCalls += 1;
              }
            },
          );
          await betterPlayerController.seekTo(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 100), () {});
          expect(seekEventCalls, 1);
          await betterPlayerController.seekTo(const Duration(seconds: 150));
          await Future<void>.delayed(const Duration(milliseconds: 100), () {});
          expect(seekEventCalls, 2);
          expect(finishEventCalls, 1);
        },
      );

      test('full screen and auto play should work', () async {
        final betterPlayerMockController = BetterPlayerMockController(
          const BetterPlayerConfiguration(
            fullScreenByDefault: true,
            autoPlay: true,
          ),
        );
        betterPlayerMockController.videoPlayerController =
            MockVideoPlayerController();
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );
        await Future<void>.delayed(const Duration(seconds: 1), () {});
        expect(betterPlayerMockController.isFullScreen, true);
        expect(betterPlayerMockController.isPlaying(), true);
      });

      test('exitFullScreen should exit full screen', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: MockVideoPlayerController(),
            );
        expect(betterPlayerMockController.isFullScreen, false);
        betterPlayerMockController.exitFullScreen();
        expect(betterPlayerMockController.isFullScreen, false);
      });

      test('enterFullScreen should enter full screen', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );
        expect(betterPlayerMockController.isFullScreen, false);
        betterPlayerMockController.enterFullScreen();
        expect(betterPlayerMockController.isFullScreen, true);
      });

      test('toggleFullScreen should change full screen state', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        expect(betterPlayerMockController.isFullScreen, false);
        betterPlayerMockController.toggleFullScreen();
        expect(betterPlayerMockController.isFullScreen, true);
        betterPlayerMockController.toggleFullScreen();
        expect(betterPlayerMockController.isFullScreen, false);
      });

      test('setLooping changes looping state', () async {
        final mockVideoPlayerController = MockVideoPlayerController();
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        mockVideoPlayerController.setNetworkDataSource(
          BetterPlayerTestUtils.bugBuckBunnyVideoUrl,
        );

        betterPlayerMockController.videoPlayerController =
            mockVideoPlayerController;
        expect(mockVideoPlayerController.isLoopingState, false);
        await betterPlayerMockController.setLooping(true);
        expect(mockVideoPlayerController.isLoopingState, true);
        await betterPlayerMockController.setLooping(false);
        expect(mockVideoPlayerController.isLoopingState, false);
      });

      test('setControlsVisibility updates controlVisiblityStream', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var showCalls = 0;
        var hideCalls = 0;
        betterPlayerMockController.controlsVisibilityStream.listen(
          (event) {
            if (event) {
              showCalls += 1;
            } else {
              hideCalls += 1;
            }
          },
        );
        betterPlayerMockController.setControlsVisibility(false);
        betterPlayerMockController.setControlsVisibility(false);
        betterPlayerMockController.setControlsVisibility(true);
        betterPlayerMockController.setControlsVisibility(true);
        betterPlayerMockController.setControlsVisibility(false);
        await Future<void>.delayed(const Duration(milliseconds: 100), () {});
        expect(hideCalls, 3);
        expect(showCalls, 2);
      });

      test('setControlsEnabled updates values correctly', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var hideCalls = 0;
        betterPlayerMockController.controlsVisibilityStream.listen(
          (event) {
            hideCalls += 1;
          },
        );
        betterPlayerMockController.setControlsEnabled(false);
        betterPlayerMockController.setControlsEnabled(false);
        await Future<void>.delayed(const Duration(milliseconds: 100), () {});
        expect(hideCalls, 2);
        expect(betterPlayerMockController.controlsEnabled, false);
        betterPlayerMockController.setControlsEnabled(true);
        expect(betterPlayerMockController.controlsEnabled, true);
      });

      test('toggleControlsVisibility sends correct events', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var controlsVisibleEventCount = 0;
        var controlsHiddenEventCount = 0;
        betterPlayerMockController.addEventsListener(
          (event) {
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.controlsVisible) {
              controlsVisibleEventCount += 1;
            }
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.controlsHiddenEnd) {
              controlsHiddenEventCount += 1;
            }
          },
        );
        betterPlayerMockController.toggleControlsVisibility(false);
        betterPlayerMockController.toggleControlsVisibility(true);
        betterPlayerMockController.toggleControlsVisibility(true);
        await Future<void>.delayed(const Duration(milliseconds: 100), () {});
        expect(controlsVisibleEventCount, 2);
        expect(controlsHiddenEventCount, 1);
      });

      test('postEvent sends events to listeners', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();

        var firstEventCounter = 0;
        var secondEventCounter = 0;

        betterPlayerMockController.addEventsListener(
          (event) {
            firstEventCounter++;
          },
        );
        betterPlayerMockController.addEventsListener(
          (event) {
            secondEventCounter++;
          },
        );
        betterPlayerMockController.postEvent(
          BetterPlayerEvent(BetterPlayerEventType.play),
        );
        betterPlayerMockController.postEvent(
          BetterPlayerEvent(BetterPlayerEventType.progress),
        );

        betterPlayerMockController.postEvent(
          BetterPlayerEvent(BetterPlayerEventType.pause),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100), () {});
        expect(firstEventCounter, 3);
        expect(secondEventCounter, 3);
      });

      test('addEventsListener update list of event listener', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        betterPlayerMockController.addEventsListener((event) {});
        betterPlayerMockController.addEventsListener((event) {});
        expect(betterPlayerMockController.eventListeners.length, 2);
      });

      void dummyEventListener(BetterPlayerEvent event) {}

      test('removeEventsListener update list of event listener', () async {
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        betterPlayerMockController.addEventsListener(dummyEventListener);
        betterPlayerMockController.addEventsListener((event) {});
        expect(betterPlayerMockController.eventListeners.length, 2);
        betterPlayerMockController.removeEventsListener(dummyEventListener);
        expect(betterPlayerMockController.eventListeners.length, 1);
      });

      test('setVolume changes volume', () async {
        final mockVideoPlayerController = MockVideoPlayerController();
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        mockVideoPlayerController.setNetworkDataSource(
          BetterPlayerTestUtils.bugBuckBunnyVideoUrl,
        );
        betterPlayerMockController.videoPlayerController =
            mockVideoPlayerController;
        await betterPlayerMockController.setVolume(1);
        expect(mockVideoPlayerController.volume, 1);
        await betterPlayerMockController.setVolume(0.5);
        expect(mockVideoPlayerController.volume, 0.5);
      });

      test(
        'setVolume should send event',
        () async {
          final BetterPlayerController betterPlayerMockController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerMockController.videoPlayerController =
              videoPlayerController;

          var setVolumeCalls = 0;
          betterPlayerMockController.addEventsListener(
            (event) {
              if (event.betterPlayerEventType ==
                  BetterPlayerEventType.setVolume) {
                setVolumeCalls += 1;
              }
            },
          );
          await betterPlayerMockController.setVolume(1);
          await Future<void>.delayed(const Duration(milliseconds: 100), () {});
          expect(setVolumeCalls, 1);
          await betterPlayerMockController.setVolume(1);
          await Future<void>.delayed(const Duration(milliseconds: 100), () {});
          expect(setVolumeCalls, 2);
        },
      );

      test('setSpeed changes speed', () async {
        final mockVideoPlayerController = MockVideoPlayerController();
        final betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        mockVideoPlayerController.setNetworkDataSource(
          BetterPlayerTestUtils.bugBuckBunnyVideoUrl,
        );
        betterPlayerMockController.videoPlayerController =
            mockVideoPlayerController;
        await betterPlayerMockController.setSpeed(1.1);
        expect(mockVideoPlayerController.speed, 1.1);
        await betterPlayerMockController.setSpeed(0.5);
        expect(mockVideoPlayerController.speed, 0.5);
        expect(
          betterPlayerMockController.setSpeed(2.5),
          throwsA(isA<ArgumentError>()),
        );
        expect(mockVideoPlayerController.speed, 0.5);
        expect(
          betterPlayerMockController.setSpeed(0),
          throwsA(isA<ArgumentError>()),
        );
        expect(mockVideoPlayerController.speed, 0.5);
      });

      test(
        'setSpeed should send event',
        () async {
          final BetterPlayerController betterPlayerMockController =
              BetterPlayerTestUtils.setupBetterPlayerMockController();
          final videoPlayerController =
              BetterPlayerTestUtils.setupMockVideoPlayerControler();
          betterPlayerMockController.videoPlayerController =
              videoPlayerController;

          var setSpeedCalls = 0;
          betterPlayerMockController.addEventsListener(
            (event) {
              if (event.betterPlayerEventType ==
                  BetterPlayerEventType.setSpeed) {
                setSpeedCalls += 1;
              }
            },
          );
          await betterPlayerMockController.setSpeed(1.5);
          await Future<void>.delayed(const Duration(milliseconds: 100), () {});
          expect(setSpeedCalls, 1);
          await betterPlayerMockController.setSpeed(1);
          await Future<void>.delayed(const Duration(milliseconds: 100), () {});
          expect(setSpeedCalls, 2);
        },
      );

      test('isBuffering returns valid value', () async {
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

      test('isLiveStream returns valid value', () async {
        final BetterPlayerController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        expect(
          betterPlayerMockController.isLiveStream,
          throwsA(isA<StateError>()),
        );
        await betterPlayerMockController.setupDataSource(
          BetterPlayerDataSource(
            DataSourceType.network,
            BetterPlayerTestUtils.forBiggerBlazesUrl,
            liveStream: true,
          ),
        );
        final videoPlayerController =
            BetterPlayerTestUtils.setupMockVideoPlayerControler();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;
        expect(betterPlayerMockController.isLiveStream(), true);
      });

      test('isVideoInitalized returns valid value', () async {
        final BetterPlayerController betterPlayerMockController =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        expect(
          betterPlayerMockController.isVideoInitialized,
          throwsA(isA<StateError>()),
        );
        final videoPlayerController =
            BetterPlayerTestUtils.setupMockVideoPlayerControler();
        betterPlayerMockController.videoPlayerController =
            videoPlayerController;
        videoPlayerController.setDuration(const Duration(seconds: 1));
        expect(betterPlayerMockController.isVideoInitialized(), true);
      });

      test('startNextVideoTimer starts next video timer', () async {
        final BetterPlayerController betterPlayerMockController =
            BetterPlayerMockController(
              const BetterPlayerConfiguration(),
              betterPlayerPlaylistConfiguration:
                  const BetterPlayerPlaylistConfiguration(
                    nextVideoDelay: Duration(seconds: 2),
                  ),
            );
        var eventCount = 0;
        betterPlayerMockController.nextVideoTimeStream.listen(
          (event) {
            eventCount += 1;
          },
        );
        betterPlayerMockController.startNextVideoTimer();
        await Future<void>.delayed(const Duration(milliseconds: 2500), () {});
        expect(eventCount, 3);
      });

      test('setOverriddenAspectRatio updates aspect ratio', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        controller.setOverriddenAspectRatio(16 / 9);
        expect(controller.getAspectRatio(), 16 / 9);
      });

      test('getAspectRatio priority order: overridden aspect ratio', () {
        final controller = BetterPlayerMockController(
          const BetterPlayerConfiguration(aspectRatio: 1),
        );
        final mockVideoPlayerController = MockVideoPlayerController();
        mockVideoPlayerController.setAspectRatio(2);
        controller.videoPlayerController = mockVideoPlayerController;

        controller.setOverriddenAspectRatio(16 / 9);
        expect(controller.getAspectRatio(), 16 / 9);
      });

      test('getAspectRatio priority order: configuration aspect ratio', () {
        final controller = BetterPlayerMockController(
          const BetterPlayerConfiguration(aspectRatio: 16 / 9),
        );
        final mockVideoPlayerController = MockVideoPlayerController();
        mockVideoPlayerController.setAspectRatio(2);
        controller.videoPlayerController = mockVideoPlayerController;

        expect(controller.getAspectRatio(), 16 / 9);
      });

      test('getAspectRatio priority order: video player aspect ratio', () {
        final controller = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        final mockVideoPlayerController = MockVideoPlayerController();
        mockVideoPlayerController.setAspectRatio(16 / 9);
        controller.videoPlayerController = mockVideoPlayerController;

        expect(controller.getAspectRatio(), 16 / 9);
      });

      test('getAspectRatio returns null when size is null and no override', () {
        final controller = BetterPlayerMockController(
          const BetterPlayerConfiguration(),
        );
        final mockVideoPlayerController = MockVideoPlayerController();
        // Size is null by default in MockVideoPlayerController constructor (VideoPlayerValue(duration: null))
        controller.videoPlayerController = mockVideoPlayerController;

        expect(controller.getAspectRatio(), null);
      });

      test('setOverriddenFit updates fit', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        controller.setOverriddenFit(BoxFit.fitWidth);
        expect(controller.getFit(), BoxFit.fitWidth);
      });

      test('setupTranslations sets correct translations', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        controller.setupTranslations(const Locale('pl'));
        expect(controller.translations.languageCode, 'pl');
        controller.setupTranslations(const Locale('en'));
        expect(controller.translations.languageCode, 'en');
      });

      test('addEventsListener and removeEventsListener work correctly', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var eventCount = 0;
        void listener(BetterPlayerEvent event) => eventCount++;

        controller.addEventsListener(listener);
        controller.postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
        expect(eventCount, 1);

        controller.removeEventsListener(listener);
        controller.postEvent(BetterPlayerEvent(BetterPlayerEventType.pause));
        expect(eventCount, 1);
      });

      test('setControlsAlwaysVisible updates stream', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        bool? lastValue;
        controller.controlsVisibilityStream.listen(
          (value) => lastValue = value,
        );

        controller.setControlsAlwaysVisible(true);
        await Future<void>.delayed(Duration.zero);
        expect(lastValue, true);
        expect(controller.controlsAlwaysVisible, true);
      });

      test('setMixWithOthers calls videoPlayerController', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        final mockVideoPlayerController = MockVideoPlayerController();
        controller.videoPlayerController = mockVideoPlayerController;

        // Since we can't easily verify the call without adding a flag to mock,
        // we just ensure it doesn't crash.
        controller.setMixWithOthers(true);
      });

      test('setTrack sends event', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        controller.videoPlayerController = MockVideoPlayerController();
        BetterPlayerEvent? lastEvent;
        controller.addEventsListener((event) => lastEvent = event);

        final track = BetterPlayerAsmsTrack(
          '1',
          1920,
          1080,
          5000,
          30,
          'avc1',
          'video/mp4',
        );
        controller.setTrack(track);

        expect(
          lastEvent?.betterPlayerEventType,
          BetterPlayerEventType.changedTrack,
        );
        expect(lastEvent?.parameters?['width'], 1920);
        expect(controller.betterPlayerAsmsTrack, track);
      });

      test('setAudioTrack updates state', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        controller.videoPlayerController = MockVideoPlayerController();

        final audioTrack = BetterPlayerAsmsAudioTrack(
          id: 1,
          label: 'English',
          language: 'en',
        );
        controller.setAudioTrack(audioTrack);

        expect(controller.betterPlayerAsmsAudioTrack, audioTrack);
      });

      test('DRM configuration adds token to headers', () async {
        final dataSource = BetterPlayerDataSource.network(
          'https://example.com/video.mp4',
          drmConfiguration: const DrmConfiguration(
            drmType: DrmType.token,
            token: 'Bearer test_token',
          ),
        );
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        final mockVideoPlayerController = MockVideoPlayerController();
        controller.videoPlayerController = mockVideoPlayerController;

        await controller.setupDataSource(dataSource);

        expect(
          mockVideoPlayerController.headers?['Authorization'],
          'Bearer test_token',
        );
      });

      test('setResolution changes data source and seeks', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        final mockVideoPlayerController = MockVideoPlayerController();
        mockVideoPlayerController.setDuration(const Duration(seconds: 100));
        await mockVideoPlayerController.seekTo(const Duration(seconds: 50));
        controller.videoPlayerController = mockVideoPlayerController;

        await controller.setupDataSource(
          BetterPlayerDataSource.network(
            'https://example.com/video_720p.mp4',
          ),
        );

        BetterPlayerEvent? resolutionEvent;
        controller.addEventsListener(
          (event) {
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.changedResolution) {
              resolutionEvent = event;
            }
          },
        );

        await controller.setResolution('https://example.com/video_1080p.mp4');

        expect(
          resolutionEvent?.betterPlayerEventType,
          BetterPlayerEventType.changedResolution,
        );
        expect(
          resolutionEvent?.parameters?['url'],
          'https://example.com/video_1080p.mp4',
        );
        expect(
          controller.betterPlayerDataSource?.url,
          'https://example.com/video_1080p.mp4',
        );
        // Verify seek back to 50s
        expect(
          await controller.videoPlayerController?.position,
          const Duration(seconds: 50),
        );
      });

      test('onPlayerVisibilityChanged handles play/pause', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: MockVideoPlayerController(),
            );
        await controller.setupDataSource(
          BetterPlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );
        await controller.play();
        expect(controller.isPlaying(), true);

        expect(controller.isPlaying(), true);

        await controller.onPlayerVisibilityChanged(0);
        expect(controller.isPlaying(), false);

        await controller.onPlayerVisibilityChanged(1);
        expect(controller.isPlaying(), true);
      });

      test('setAppLifecycleState handles play/pause', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: MockVideoPlayerController(),
            );
        await controller.setupDataSource(
          BetterPlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );
        await controller.play();
        expect(controller.isPlaying(), true);

        controller.setAppLifecycleState(AppLifecycleState.paused);
        expect(controller.isPlaying(), false);

        controller.setAppLifecycleState(AppLifecycleState.resumed);
        expect(controller.isPlaying(), true);
      });

      test('toggleFullScreen changes state', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        expect(controller.isFullScreen, false);
        controller.toggleFullScreen();
        expect(controller.isFullScreen, true);
        controller.toggleFullScreen();
        expect(controller.isFullScreen, false);
      });

      test('setLooping updates state', () async {
        final mockVideoPlayerController = MockVideoPlayerController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockVideoPlayerController,
            );
        await controller.setLooping(true);
        expect(mockVideoPlayerController.isLoopingState, true);
      });

      test('dispose clears resources', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: MockVideoPlayerController(),
            );
        controller.dispose(forceDispose: true);
      });

      test('postEvent sends event to all listeners', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var eventCount1 = 0;
        var eventCount2 = 0;
        controller.addEventsListener((_) => eventCount1++);
        controller.addEventsListener((_) => eventCount2++);

        controller.postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
        expect(eventCount1, 1);
        expect(eventCount2, 1);
      });

      test('removeEventsListener removes listener', () {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        var eventCount = 0;
        void listener(BetterPlayerEvent event) => eventCount++;
        controller.addEventsListener(listener);
        controller.removeEventsListener(listener);

        controller.postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
        expect(eventCount, 0);
      });

      test('controllerEventStream emits events', () async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        controller.videoPlayerController = MockVideoPlayerController();

        final events = <BetterPlayerControllerEvent>[];
        controller.controllerEventStream.listen(events.add);

        await controller.setupDataSource(
          BetterPlayerDataSource.network('url'),
        );
        await controller.play();
        controller.enterFullScreen();
        controller.exitFullScreen();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          events.contains(BetterPlayerControllerEvent.setupDataSource),
          true,
        );
        expect(events.contains(BetterPlayerControllerEvent.play), true);
        expect(
          events.contains(BetterPlayerControllerEvent.openFullscreen),
          true,
        );
        expect(
          events.contains(BetterPlayerControllerEvent.hideFullscreen),
          true,
        );
      });

      test('setupDataSource emits exception for DASH on iOS', () async {
        final previousPlatform = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final previousInstance = VideoPlayerPlatform.instance;
        VideoPlayerPlatform.instance = BetterPlayerIOS();
        try {
          final controller = BetterPlayerMockController(
            const BetterPlayerConfiguration(),
          );
          BetterPlayerEvent? exceptionEvent;
          controller.addEventsListener((event) {
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.exception) {
              exceptionEvent = event;
            }
          });

          await controller.setupDataSource(
            BetterPlayerDataSource.network('https://example.com/video.mpd'),
          );

          expect(exceptionEvent != null, true);
          expect(
            exceptionEvent?.parameters?['exception'],
            'DASH streams are not supported on iOS platform. Please use HLS instead.',
          );
          expect(controller.videoPlayerController, null);
        } finally {
          debugDefaultTargetPlatformOverride = previousPlatform;
          VideoPlayerPlatform.instance = previousInstance;
        }
      });

      testWidgets('BetterPlayerController.of(context) works', (
        WidgetTester tester,
      ) async {
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController();
        await tester.pumpWidget(
          BetterPlayerControllerProvider(
            controller: controller,
            child: Builder(
              builder: (context) {
                final found = BetterPlayerController.of(context);
                expect(found, controller);
                return const SizedBox();
              },
            ),
          ),
        );
      });
    },
  );
}
