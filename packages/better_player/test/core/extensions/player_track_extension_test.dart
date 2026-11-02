import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';
import '../../helpers/mock_player_engine_controller.dart';

class _TrackingEngineController extends MockPlayerEngineController {
  int? lastWidth;
  int? lastHeight;
  int? lastBitrate;
  String? lastAudioName;
  int? lastAudioIndex;
  bool? lastMixWithOthers;

  @override
  Future<void> setTrackParameters({
    int? width,
    int? height,
    int? bitrate,
  }) async {
    lastWidth = width;
    lastHeight = height;
    lastBitrate = bitrate;
  }

  @override
  Future<void> setAudioTrack(String? name, int? index) async {
    lastAudioName = name;
    lastAudioIndex = index;
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {
    lastMixWithOthers = mixWithOthers;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerTrackExtension without initialized engine', () {
    late BetterPlayerController controller;

    setUp(() {
      controller = BetterPlayerController(const PlayerConfiguration());
    });

    tearDown(() {
      controller.dispose();
    });

    test('setTrack throws StateError when engine is null', () {
      expect(
        () => controller.setTrack(
          PlayerAsmsTrack('1', 1920, 1080, 5000000, null, null, null),
        ),
        throwsStateError,
      );
    });

    test('setAudioTrack throws StateError when engine is null', () {
      expect(
        () => controller.setAudioTrack(
          PlayerAsmsAudioTrack(id: 1, label: 'English'),
        ),
        throwsStateError,
      );
    });

    test('setMixWithOthers throws StateError when engine is null', () {
      expect(
        () => controller.setMixWithOthers(true),
        throwsStateError,
      );
    });

    test('setTrackParameters throws StateError when engine is null', () async {
      expect(
        () => controller.setTrackParameters(width: 1280, height: 720),
        throwsStateError,
      );
    });
  });

  group('PlayerTrackExtension with engine', () {
    late BetterPlayerController controller;
    late _TrackingEngineController trackingEngine;

    setUp(() {
      trackingEngine = _TrackingEngineController();
      controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: trackingEngine,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('setTrack with defaultTrack resets dimensions and bitrate to 0', () {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      final defaultTrack = PlayerAsmsTrack.defaultTrack();
      controller.setTrack(defaultTrack);

      expect(trackingEngine.lastWidth, 0);
      expect(trackingEngine.lastHeight, 0);
      expect(trackingEngine.lastBitrate, 0);
      expect(controller.betterPlayerAsmsTrack, defaultTrack);
      expect(
        events.any(
          (e) => e.betterPlayerEventType == PlayerEventType.changedTrack,
        ),
        isTrue,
      );
    });

    test('setTrack with specific track configures engine and trackState', () {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      final track = PlayerAsmsTrack(
        'hd',
        1920,
        1080,
        4500000,
        30,
        null,
        null,
      );
      controller.setTrack(track);

      expect(trackingEngine.lastWidth, 1920);
      expect(trackingEngine.lastHeight, 1080);
      expect(trackingEngine.lastBitrate, 4500000);
      expect(controller.betterPlayerAsmsTrack, track);

      final event = events.firstWhere(
        (e) => e.betterPlayerEventType == PlayerEventType.changedTrack,
      );
      expect(event.parameters?['id'], 'hd');
      expect(event.parameters?['width'], 1920);
      expect(event.parameters?['height'], 1080);
    });

    test('setAudioTrack configures engine and updates trackState', () {
      final audioTrack = PlayerAsmsAudioTrack(
        id: 2,
        label: 'Spanish',
        language: 'es',
      );
      controller.setAudioTrack(audioTrack);

      expect(trackingEngine.lastAudioName, 'Spanish');
      expect(trackingEngine.lastAudioIndex, 2);
      expect(controller.betterPlayerAsmsAudioTrack, audioTrack);
    });

    test('setAudioTrack with empty track clears asmsAudioTrack', () {
      final audioTrack = PlayerAsmsAudioTrack(
        id: 2,
        label: 'Spanish',
        language: 'es',
      );
      controller.setAudioTrack(audioTrack);
      expect(controller.betterPlayerAsmsAudioTrack, isNotNull);

      // Clearing track
      controller.setAudioTrack(PlayerAsmsAudioTrack());
      expect(controller.betterPlayerAsmsAudioTrack, isNull);
    });

    test('setMixWithOthers sets mix parameter on engine', () {
      controller.setMixWithOthers(true);
      expect(trackingEngine.lastMixWithOthers, isTrue);

      controller.setMixWithOthers(false);
      expect(trackingEngine.lastMixWithOthers, isFalse);
    });

    test('setTrackParameters directly passes dimensions and bitrate', () async {
      await controller.setTrackParameters(
        width: 854,
        height: 480,
        bitrate: 1200000,
      );

      expect(trackingEngine.lastWidth, 854);
      expect(trackingEngine.lastHeight, 480);
      expect(trackingEngine.lastBitrate, 1200000);
    });
  });
}
