import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';
import '../../helpers/mock_player_engine_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerPlaybackExtension without initialized engine', () {
    late BetterPlayerController controller;

    setUp(() {
      controller = BetterPlayerController(const PlayerConfiguration());
    });

    tearDown(() {
      controller.dispose();
    });

    test('play throws StateError when engine is null', () async {
      expect(controller.play, throwsStateError);
    });

    test('pause throws StateError when engine is null', () async {
      expect(controller.pause, throwsStateError);
    });

    test('setLooping throws StateError when engine is null', () async {
      expect(() => controller.setLooping(true), throwsStateError);
    });

    test('seekTo throws StateError when engine is null', () async {
      expect(() => controller.seekTo(Duration.zero), throwsStateError);
    });

    test('setVolume throws StateError when engine is null', () async {
      expect(() => controller.setVolume(0.5), throwsStateError);
    });

    test('setSpeed throws StateError when engine is null', () async {
      expect(() => controller.setSpeed(1.5), throwsStateError);
    });

    test('isPlaying throws StateError when engine is null', () {
      expect(controller.isPlaying, throwsStateError);
    });

    test('isBuffering throws StateError when engine is null', () {
      expect(controller.isBuffering, throwsStateError);
    });
  });

  group('PlayerPlaybackExtension argument validations', () {
    late BetterPlayerController controller;
    late MockPlayerEngineController mockEngine;

    setUp(() {
      mockEngine = MockPlayerEngineController();
      controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockEngine,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('setVolume throws ArgumentError for invalid values', () {
      expect(() => controller.setVolume(-0.1), throwsArgumentError);
      expect(() => controller.setVolume(1.1), throwsArgumentError);
    });

    test('setSpeed throws ArgumentError for invalid values', () {
      expect(() => controller.setSpeed(0), throwsArgumentError);
      expect(() => controller.setSpeed(-1), throwsArgumentError);
      expect(() => controller.setSpeed(10.5), throwsArgumentError);
    });
  });

  group('PlayerPlaybackExtension with engine operations', () {
    late BetterPlayerController controller;
    late MockPlayerEngineController mockEngine;

    setUp(() {
      mockEngine = MockPlayerEngineController();
      controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockEngine,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('play starts playback, updates state, and posts events', () async {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      await controller.play();

      expect(mockEngine.value.isPlaying, isTrue);
      expect(controller.hasCurrentDataSourceStarted, isTrue);
      expect(
        events.any((e) => e.betterPlayerEventType == PlayerEventType.play),
        isTrue,
      );
    });

    test('pause pauses engine and posts pause event', () async {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      await controller.play();
      await controller.pause();

      expect(mockEngine.value.isPlaying, isFalse);
      expect(
        events.any((e) => e.betterPlayerEventType == PlayerEventType.pause),
        isTrue,
      );
    });

    test('setLooping updates engine looping state', () async {
      await controller.setLooping(true);
      expect(mockEngine.isLoopingState, isTrue);

      await controller.setLooping(false);
      expect(mockEngine.isLoopingState, isFalse);
    });

    test('setVolume updates engine and posts setVolume event', () async {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      await controller.setVolume(0.75);

      expect(mockEngine.volume, 0.75);
      final volumeEvent = events.firstWhere(
        (e) => e.betterPlayerEventType == PlayerEventType.setVolume,
      );
      expect(
        volumeEvent.parameters?[PlayerEventConstants.volumeParameter],
        0.75,
      );
    });

    test('setSpeed updates engine and posts setSpeed event', () async {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      await controller.setSpeed(2);

      expect(mockEngine.speed, 2);
      final speedEvent = events.firstWhere(
        (e) => e.betterPlayerEventType == PlayerEventType.setSpeed,
      );
      expect(speedEvent.parameters?[PlayerEventConstants.speedParameter], 2);
    });

    test('setSpeed supports speeds up to 10.0', () async {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      await controller.setSpeed(5);
      expect(mockEngine.speed, 5);

      await controller.setSpeed(10);
      expect(mockEngine.speed, 10);

      final speedEvents = events
          .where(
            (e) => e.betterPlayerEventType == PlayerEventType.setSpeed,
          )
          .toList();
      expect(speedEvents, hasLength(2));
      expect(
        speedEvents.first.parameters?[PlayerEventConstants.speedParameter],
        5,
      );
      expect(
        speedEvents.last.parameters?[PlayerEventConstants.speedParameter],
        10,
      );
    });

    test('seekTo updates engine position and posts seekTo event', () async {
      mockEngine.emitInitialized();
      mockEngine.setDuration(const Duration(seconds: 100));

      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      const target = Duration(seconds: 45);
      await controller.seekTo(target);

      expect(mockEngine.lastSeekPosition, target);
      final seekEvent = events.firstWhere(
        (e) => e.betterPlayerEventType == PlayerEventType.seekTo,
      );
      expect(
        seekEvent.parameters?[PlayerEventConstants.durationParameter],
        target,
      );
    });

    test('seekTo beyond duration posts finished event', () async {
      mockEngine.emitInitialized();
      mockEngine.setDuration(const Duration(seconds: 50));

      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      await controller.seekTo(const Duration(seconds: 60));

      expect(
        events.any((e) => e.betterPlayerEventType == PlayerEventType.finished),
        isTrue,
      );
    });

    test('isPlaying and isBuffering query engine value', () {
      mockEngine.value = mockEngine.value.copyWith(
        isPlaying: true,
        isBuffering: false,
      );

      expect(controller.isPlaying(), isTrue);
      expect(controller.isBuffering(), isFalse);

      mockEngine.value = mockEngine.value.copyWith(isBuffering: true);
      expect(controller.isBuffering(), isTrue);
    });
  });
}
