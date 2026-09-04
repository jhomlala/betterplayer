import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/state/player_track_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerTrackState', () {
    test('should initialize with correct default values', () {
      const state = PlayerTrackState();

      expect(state.asmsTracks, isEmpty);
      expect(state.asmsTrack, isNull);
      expect(state.asmsAudioTracks, isEmpty);
      expect(state.asmsAudioTrack, isNull);
    });

    test('should allow updating fields', () {
      var state = const PlayerTrackState();

      final videoTrack = PlayerAsmsTrack(
        '1',
        1080,
        1920,
        5000000,
        0,
        'en',
        'url',
      );
      final audioTrack = PlayerAsmsAudioTrack(
        id: 1,
        label: 'English',
        language: 'en',
        url: 'url',
      );

      state = state.copyWith(asmsTracks: [...state.asmsTracks, videoTrack]);
      state = state.copyWith(asmsTrack: videoTrack);
      state = state.copyWith(asmsAudioTracks: [...state.asmsAudioTracks, audioTrack]);
      state = state.copyWith(asmsAudioTrack: audioTrack);

      expect(state.asmsTracks, hasLength(1));
      expect(state.asmsTrack, videoTrack);
      expect(state.asmsAudioTracks, hasLength(1));
      expect(state.asmsAudioTrack, audioTrack);
    });
  });
}
