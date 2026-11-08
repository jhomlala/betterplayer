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
  List<Map<String, dynamic>> nativeTracks = const [];
  bool throwOnGetAudioTracks = false;

  @override
  Future<List<Map<String, dynamic>>> getAudioTracks() async {
    if (throwOnGetAudioTracks) {
      throw Exception('Simulated native track query failure');
    }
    return nativeTracks;
  }

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
          const PlayerAsmsTrack('1', 1920, 1080, 5000000, null, null, null),
        ),
        throwsStateError,
      );
    });

    test('getAudioTracks returns empty list when engine is null', () async {
      final tracks = await controller.getAudioTracks();
      expect(tracks, isEmpty);
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
      expect(() => controller.setMixWithOthers(true), throwsStateError);
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

      const track = PlayerAsmsTrack('hd', 1920, 1080, 4500000, 30, null, null);
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

    test(
      'getAudioTracks queries native engine and populates trackState',
      () async {
        trackingEngine.nativeTracks = [
          <String, dynamic>{
            'index': 0,
            'label': 'Japanese',
            'language': 'ja',
            'mimeType': 'audio/aac',
          },
          <String, dynamic>{'index': 1, 'label': 'English', 'language': 'en'},
        ];

        final tracks = await controller.getAudioTracks();
        expect(tracks, hasLength(2));
        expect(tracks[0].id, 0);
        expect(tracks[0].label, 'Japanese');
        expect(tracks[0].language, 'ja');
        expect(tracks[0].mimeType, 'audio/aac');
        expect(tracks[1].id, 1);
        expect(tracks[1].label, 'English');
        expect(tracks[1].language, 'en');

        expect(controller.betterPlayerAsmsAudioTracks, hasLength(2));
        expect(controller.betterPlayerAsmsAudioTrack?.label, 'Japanese');
      },
    );

    test('getAudioTracks returns cached tracks if already present', () async {
      trackingEngine.nativeTracks = [
        <String, dynamic>{'index': 0, 'label': 'First Fetch'},
      ];

      final firstTracks = await controller.getAudioTracks();
      expect(firstTracks.first.label, 'First Fetch');

      // Now change native tracks on engine:
      trackingEngine.nativeTracks = [
        <String, dynamic>{'index': 99, 'label': 'Second Fetch'},
      ];

      // Second call returns cached tracks from trackState
      final cachedTracks = await controller.getAudioTracks();
      expect(cachedTracks.first.label, 'First Fetch');
    });

    test(
      'getAudioTracks handles engine exceptions and returns empty list',
      () async {
        trackingEngine.throwOnGetAudioTracks = true;

        final tracks = await controller.getAudioTracks();
        expect(tracks, isEmpty);
        expect(controller.betterPlayerAsmsAudioTracks, isEmpty);
      },
    );

    test(
      'getAudioTracks populates default values when fields are absent',
      () async {
        trackingEngine.nativeTracks = [
          <String, dynamic>{'index': 0},
        ];

        final tracks = await controller.getAudioTracks();
        expect(tracks, hasLength(1));
        expect(tracks.first.id, 0);
        expect(tracks.first.label, 'Track 0');
        expect(tracks.first.language, 'und');
        expect(tracks.first.mimeType, isNull);
      },
    );

    test('getAudioTracks preserves selected track if already chosen', () async {
      final preselected = PlayerAsmsAudioTrack(id: 99, label: 'Custom');
      controller.setAudioTrack(preselected);

      trackingEngine.nativeTracks = [
        <String, dynamic>{'index': 0, 'label': 'Discovered 1'},
        <String, dynamic>{'index': 1, 'label': 'Discovered 2'},
      ];

      await controller.getAudioTracks();
      expect(controller.betterPlayerAsmsAudioTrack, preselected);
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
