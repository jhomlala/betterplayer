import 'package:better_player/better_player.dart';

/// Tracks the audio and video tracks parsed from ASMS (HLS/DASH) manifests.
class PlayerTrackState {
  /// Complete list of video quality tracks parsed from ASMS manifests.
  List<PlayerAsmsTrack> asmsTracks = [];

  /// The specific ASMS (HLS/DASH) video track currently selected for playback.
  PlayerAsmsTrack? asmsTrack;

  /// Complete list of alternative audio tracks parsed from ASMS manifests.
  List<PlayerAsmsAudioTrack> asmsAudioTracks = [];

  /// The specific ASMS (HLS/DASH) audio track currently selected for playback.
  PlayerAsmsAudioTrack? asmsAudioTrack;
}
