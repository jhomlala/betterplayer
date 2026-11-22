import 'package:better_player_cast/src/models/cast_player_state.dart';
import 'package:meta/meta.dart';

/// Current playback status returned by a Cast receiver.
@immutable
class CastMediaStatus {
  /// Creates a media status snapshot.
  const CastMediaStatus({
    required this.mediaSessionId,
    required this.playerState,
    required this.currentTime,
    this.duration,
    this.volume = 1.0,
    this.muted = false,
    this.contentId,
  });

  /// Factory constructor to parse a raw CastV2 status JSON map.
  factory CastMediaStatus.fromJson(Map<String, dynamic> json) {
    final mediaSessionId = json['mediaSessionId'] as int? ?? 0;
    final stateStr = json['playerState'] as String? ?? 'IDLE';
    final playerState = _parsePlayerState(stateStr);

    final currentSec = (json['currentTime'] as num?)?.toDouble() ?? 0.0;
    final currentTime = Duration(milliseconds: (currentSec * 1000).round());

    Duration? duration;
    final media = json['media'] as Map<String, dynamic>?;
    String? contentId;
    if (media != null) {
      contentId = media['contentId'] as String?;
      final durationSec = (media['duration'] as num?)?.toDouble();
      if (durationSec != null && durationSec > 0) {
        duration = Duration(milliseconds: (durationSec * 1000).round());
      }
    }

    var volume = 1.0;
    var muted = false;
    final volumeObj = json['volume'] as Map<String, dynamic>?;
    if (volumeObj != null) {
      volume = (volumeObj['level'] as num?)?.toDouble() ?? 1.0;
      muted = volumeObj['muted'] as bool? ?? false;
    }

    return CastMediaStatus(
      mediaSessionId: mediaSessionId,
      playerState: playerState,
      currentTime: currentTime,
      duration: duration,
      volume: volume,
      muted: muted,
      contentId: contentId,
    );
  }

  /// Active media session identifier on the receiver.
  final int mediaSessionId;

  /// Current state of the remote player.
  final CastPlayerState playerState;

  /// Current playback position on the receiver.
  final Duration currentTime;

  /// Total duration of the media if known.
  final Duration? duration;

  /// Current volume level (0.0 to 1.0).
  final double volume;

  /// Whether audio is muted on the receiver.
  final bool muted;

  /// Content identifier (URL) of the active media.
  final String? contentId;

  static CastPlayerState _parsePlayerState(String state) {
    switch (state.toUpperCase()) {
      case 'PLAYING':
        return CastPlayerState.playing;
      case 'PAUSED':
        return CastPlayerState.paused;
      case 'BUFFERING':
        return CastPlayerState.buffering;
      case 'LOADING':
        return CastPlayerState.loading;
      case 'IDLE':
      default:
        return CastPlayerState.idle;
    }
  }

  @override
  String toString() =>
      'CastMediaStatus(session: $mediaSessionId, state: $playerState, time: $currentTime, duration: $duration)';
}
