import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/state/player_track_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerTrackState', () {
    test('should initialize with correct default values', () {
      final state = PlayerTrackState();

      expect(state.asmsTracks, isEmpty);
      expect(state.asmsTrack, isNull);
      expect(state.asmsAudioTracks, isEmpty);
      expect(state.asmsAudioTrack, isNull);
    });

    test('should allow updating fields', () {
      final state = PlayerTrackState();
      
      final videoTrack = PlayerAsmsTrack('1', 1080, 1920, 5000000, 0, 'en', 'url');
      final audioTrack = PlayerAsmsAudioTrack(id: 1, label: 'English', language: 'en', url: 'url');

      state.asmsTracks.add(videoTrack);
      state.asmsTrack = videoTrack;
      state.asmsAudioTracks.add(audioTrack);
      state.asmsAudioTrack = audioTrack;

      expect(state.asmsTracks, hasLength(1));
      expect(state.asmsTrack, videoTrack);
      expect(state.asmsAudioTracks, hasLength(1));
      expect(state.asmsAudioTrack, audioTrack);
    });
  });
}
