import 'dart:ui';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/state/player_playback_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerPlaybackState', () {
    test('should initialize with correct default values', () {
      final state = PlayerPlaybackState();

      expect(state.hasCurrentDataSourceStarted, isFalse);
      expect(state.hasCurrentDataSourceInitialized, isFalse);
      expect(state.appLifecycleState, AppLifecycleState.resumed);
      expect(state.wasPlayingBeforePause, isNull);
      expect(state.videoPlayerValueOnError, isNull);
      expect(state.lastPositionSelection, 0);
    });

    test('should allow updating fields', () {
      final state = PlayerPlaybackState();
      
      final errorValue = VideoPlayerValue(duration: const Duration(seconds: 10));

      state.hasCurrentDataSourceStarted = true;
      state.hasCurrentDataSourceInitialized = true;
      state.appLifecycleState = AppLifecycleState.paused;
      state.wasPlayingBeforePause = true;
      state.videoPlayerValueOnError = errorValue;
      state.lastPositionSelection = 12345;

      expect(state.hasCurrentDataSourceStarted, isTrue);
      expect(state.hasCurrentDataSourceInitialized, isTrue);
      expect(state.appLifecycleState, AppLifecycleState.paused);
      expect(state.wasPlayingBeforePause, isTrue);
      expect(state.videoPlayerValueOnError, errorValue);
      expect(state.lastPositionSelection, 12345);
    });
  });
}
