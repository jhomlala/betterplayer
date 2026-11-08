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

    final isDefaultTrack = track == PlayerAsmsTrack.defaultTrack();
    if (isDefaultTrack) {
      _engine!.setTrackParameters(width: 0, height: 0, bitrate: 0);
    } else {
      final effectiveBitrate = (track.bitrate ?? 0) > 0 ? track.bitrate : null;
      final hasSize = (track.width ?? 0) > 0 && (track.height ?? 0) > 0;
      _engine!.setTrackParameters(
        width: hasSize ? track.width : null,
        height: hasSize ? track.height : null,
        bitrate: effectiveBitrate,
      );
    }
    _trackState = _trackState.copyWith(asmsTrack: track);
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
    await pause();
    await setupDataSource(betterPlayerDataSource!.copyWith(url: url));
    if (position != null) {
      await seekTo(position);
    }
    if (wasPlayingBeforeChange) {
      await play();
    }
    _postEvent(
      PlayerEvent(
        PlayerEventType.changedResolution,
        parameters: <String, dynamic>{'url': url},
      ),
    );
  }

  /// Retrieves the list of available audio tracks.
  ///
  /// If ASMS tracks were detected from an HLS or DASH manifest, returns them.
  /// Otherwise queries the native player for embedded container audio tracks (MKV, MP4, etc.).
  Future<List<PlayerAsmsAudioTrack>> getAudioTracks() async {
    if (_trackState.asmsAudioTracks.isNotEmpty) {
      return _trackState.asmsAudioTracks;
    }
    if (_engine == null) {
      return const <PlayerAsmsAudioTrack>[];
    }
    try {
      final nativeTracks = await _engine!.getAudioTracks();
      final parsed = <PlayerAsmsAudioTrack>[];
      for (final track in nativeTracks) {
        final index = track['index'] as int? ?? 0;
        final label = track['label'] as String?;
        final language = track['language'] as String?;
        final mimeType = track['mimeType'] as String?;
        parsed.add(
          PlayerAsmsAudioTrack(
            id: index,
            label: label ?? language ?? 'Track $index',
            language: language ?? 'und',
            mimeType: mimeType,
          ),
        );
      }
      if (parsed.isNotEmpty) {
        _trackState = _trackState.copyWith(asmsAudioTracks: parsed);
        if (_trackState.asmsAudioTrack == null) {
          _trackState = _trackState.copyWith(asmsAudioTrack: parsed.first);
        }
      }
      return parsed;
    } on Object catch (e) {
      PlayerLogger.warning(
        message: 'Failed to retrieve native audio tracks: $e',
        textureId: textureId,
      );
      return const <PlayerAsmsAudioTrack>[];
    }
  }

  ///Set [audioTrack] in player.
  void setAudioTrack(PlayerAsmsAudioTrack audioTrack) {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    if (audioTrack.language == null && audioTrack.id == null) {
      _trackState = _trackState.copyWith(clearAsmsAudioTrack: true);
      return;
    }

    _trackState = _trackState.copyWith(asmsAudioTrack: audioTrack);
    _engine!.setAudioTrack(audioTrack.label, audioTrack.id);
  }

  ///Enable or disable audio mixing with other sound within device.
  void setMixWithOthers(bool mixWithOthers) {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    _engine!.setMixWithOthers(mixWithOthers);
  }

  /// Sets track parameters directly on the engine (width, height, bitrate).
  /// Prefer [setTrack] with a [PlayerAsmsTrack] for HLS/DASH streams.
  Future<void> setTrackParameters({
    int? width,
    int? height,
    int? bitrate,
  }) async {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    await _engine!.setTrackParameters(
      width: width,
      height: height,
      bitrate: bitrate,
    );
  }
}
