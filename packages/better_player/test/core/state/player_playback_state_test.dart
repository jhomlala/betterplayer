import 'dart:ui';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/state/player_playback_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerPlaybackState', () {
    test('should initialize with correct default values', () {
      const state = PlayerPlaybackState();

      expect(state.hasCurrentDataSourceStarted, isFalse);
      expect(state.hasCurrentDataSourceInitialized, isFalse);
      expect(state.appLifecycleState, AppLifecycleState.resumed);
      expect(state.wasPlayingBeforePause, isNull);
      expect(state.videoPlayerValueOnError, isNull);
      expect(state.lastPositionSelection, 0);
    });

    test('should allow updating fields', () {
      var state = const PlayerPlaybackState();

      final errorValue = VideoPlayerValue(
        duration: const Duration(seconds: 10),
      );

      state = state.copyWith(hasCurrentDataSourceStarted: true);
      state = state.copyWith(hasCurrentDataSourceInitialized: true);
      state = state.copyWith(appLifecycleState: AppLifecycleState.paused);
      state = state.copyWith(wasPlayingBeforePause: true);
      state = state.copyWith(videoPlayerValueOnError: errorValue);
      state = state.copyWith(lastPositionSelection: 12345);

      expect(state.hasCurrentDataSourceStarted, isTrue);
      expect(state.hasCurrentDataSourceInitialized, isTrue);
      expect(state.appLifecycleState, AppLifecycleState.paused);
      expect(state.wasPlayingBeforePause, isTrue);
      expect(state.videoPlayerValueOnError, errorValue);
      expect(state.lastPositionSelection, 12345);
    });
  });
}
