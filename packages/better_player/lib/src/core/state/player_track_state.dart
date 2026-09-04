import 'package:better_player/better_player.dart';
import 'package:flutter/foundation.dart';

/// Tracks the audio and video quality selections available via ASMS formats.
@immutable
class PlayerTrackState {
  /// Complete list of alternative video tracks (resolutions, bitrates) parsed from ASMS streams.
  final List<PlayerAsmsTrack> asmsTracks;

  /// The currently active video track selection.
  final PlayerAsmsTrack? asmsTrack;

  /// Complete list of alternative audio tracks (languages, codecs) parsed from ASMS streams.
  final List<PlayerAsmsAudioTrack> asmsAudioTracks;

  /// The currently active audio track selection.
  final PlayerAsmsAudioTrack? asmsAudioTrack;

  const PlayerTrackState({
    this.asmsTracks = const [],
    this.asmsTrack,
    this.asmsAudioTracks = const [],
    this.asmsAudioTrack,
  });

  PlayerTrackState copyWith({
    List<PlayerAsmsTrack>? asmsTracks,
    PlayerAsmsTrack? asmsTrack,
    List<PlayerAsmsAudioTrack>? asmsAudioTracks,
    PlayerAsmsAudioTrack? asmsAudioTrack,
    bool clearAsmsTrack = false,
    bool clearAsmsAudioTrack = false,
  }) {
    return PlayerTrackState(
      asmsTracks: asmsTracks ?? this.asmsTracks,
      asmsTrack: clearAsmsTrack ? null : (asmsTrack ?? this.asmsTrack),
      asmsAudioTracks: asmsAudioTracks ?? this.asmsAudioTracks,
      asmsAudioTrack: clearAsmsAudioTrack
          ? null
          : (asmsAudioTrack ?? this.asmsAudioTrack),
    );
  }
}
