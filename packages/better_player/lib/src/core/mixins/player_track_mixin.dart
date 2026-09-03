part of '../better_player_controller.dart';

extension PlayerTrackExtension on BetterPlayerController {
  ///Setup track parameters for currently played video. Can be only used for HLS or DASH
  ///data source.
  void setTrack(PlayerAsmsTrack track) {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    _postEvent(
      PlayerEvent(
        PlayerEventType.changedTrack,
        parameters: <String, dynamic>{
          'id': track.id,
          'width': track.width,
          'height': track.height,
          'bitrate': track.bitrate,
          'frameRate': track.frameRate,
          'codecs': track.codecs,
          'mimeType': track.mimeType,
        },
      ),
    );

    _engine!.setTrackParameters(
      width: track.width,
      height: track.height,
      bitrate: track.bitrate,
    );
    _betterPlayerAsmsTrack = track;
  }

  ///Set different resolution (quality) for video
  Future<void> setResolution(String url) async {
    PlayerLogger.info(
      message: 'Resolution changed to: $url',
      textureId: textureId,
    );
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    final position = await _engine!.position;
    final wasPlayingBeforeChange = isPlaying()!;
    pause();
    await setupDataSource(betterPlayerDataSource!.copyWith(url: url));
    seekTo(position!);
    if (wasPlayingBeforeChange) {
      play();
    }
    _postEvent(
      PlayerEvent(
        PlayerEventType.changedResolution,
        parameters: <String, dynamic>{'url': url},
      ),
    );
  }

  ///Set [audioTrack] in player. Works only for HLS or DASH streams.
  void setAudioTrack(PlayerAsmsAudioTrack audioTrack) {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    if (audioTrack.language == null) {
      _betterPlayerAsmsAudioTrack = null;
      return;
    }

    _betterPlayerAsmsAudioTrack = audioTrack;
    _engine!.setAudioTrack(audioTrack.label, audioTrack.id);
  }

  ///Enable or disable audio mixing with other sound within device.
  void setMixWithOthers(bool mixWithOthers) {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    _engine!.setMixWithOthers(mixWithOthers);
  }
}
