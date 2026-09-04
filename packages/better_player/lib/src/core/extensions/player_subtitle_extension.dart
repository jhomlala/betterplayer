part of '../better_player_controller.dart';

extension PlayerSubtitleExtension on BetterPlayerController {
  ///Configure subtitles based on subtitles source.
  void _setupSubtitles() {
    _subtitleState.subtitlesSourceList.add(
      PlayerSubtitlesSource(type: PlayerSubtitlesSourceType.none),
    );
    final defaultSubtitle = _subtitleState.subtitlesSourceList.firstWhereOrNull(
      (element) => element.selectedByDefault == true,
    );

    ///Setup subtitles (none is default)
    setupSubtitleSource(
      defaultSubtitle ?? _subtitleState.subtitlesSourceList.last,
      sourceInitialize: true,
    );
  }

  ///Setup subtitles to be displayed from given subtitle source.
  ///If subtitles source is segmented then don't load videos at start. Videos
  ///will load with just in time policy.
  Future<void> setupSubtitleSource(
    PlayerSubtitlesSource subtitlesSource, {
    bool sourceInitialize = false,
  }) async {
    _subtitleState.subtitlesSource = subtitlesSource;
    _subtitleState.subtitlesLines.clear();
    _subtitleState.asmsSegmentsLoaded.clear();
    _subtitleState.asmsSegmentsLoading = false;

    if (subtitlesSource.type != PlayerSubtitlesSourceType.none) {
      if (subtitlesSource.asmsIsSegmented == true) {
        return;
      }
      final subtitlesParsed = await PlayerSubtitlesFactory.parseSubtitles(
        subtitlesSource,
      );
      _subtitleState.subtitlesLines.addAll(subtitlesParsed);
    }

    _postEvent(PlayerEvent(PlayerEventType.changedSubtitles));
    if (!_disposed && !sourceInitialize) {
      _postControllerEvent(PlayerControllerEvent.changeSubtitles);
    }
  }

  ///Load ASMS subtitles segments for given [position].
  ///Segments are being loaded within range (current video position;endPosition)
  ///where endPosition is based on time segment detected in HLS playlist. If
  ///time segment is not present then 5000 ms will be used. Also time segment
  ///is multiplied by 5 to increase window of duration.
  ///Segments are also cached, so same segment won't load twice. Only one
  ///pack of segments can be load at given time.
  Future _loadAsmsSubtitlesSegments(Duration position) async {
    try {
      if (_subtitleState.asmsSegmentsLoading) {
        return;
      }
      _subtitleState.asmsSegmentsLoading = true;
      final source = _subtitleState.subtitlesSource;
      final loadDurationEnd = Duration(
        milliseconds:
            position.inMilliseconds +
            5 * (_subtitleState.subtitlesSource?.asmsSegmentsTime ?? 5000),
      );

      final segmentsToLoad = _subtitleState.subtitlesSource?.asmsSegments
          ?.where((segment) {
            return segment.endTime > position &&
                segment.startTime < loadDurationEnd &&
                !_subtitleState.asmsSegmentsLoaded.contains(segment.realUrl);
          })
          .map((segment) => segment.realUrl)
          .toList();

      if (segmentsToLoad != null && segmentsToLoad.isNotEmpty) {
        final subtitlesParsed = await PlayerSubtitlesFactory.parseSubtitles(
          PlayerSubtitlesSource(
            type: _subtitleState.subtitlesSource!.type,
            headers: _subtitleState.subtitlesSource!.headers,
            urls: segmentsToLoad,
          ),
        );

        ///Additional check if current source of subtitles is same as source
        ///used to start loading subtitles. It can be different when user
        ///changes subtitles and there was already pending load.
        if (source == _subtitleState.subtitlesSource) {
          _subtitleState.subtitlesLines.addAll(subtitlesParsed);
          _subtitleState.asmsSegmentsLoaded.addAll(segmentsToLoad);
        }
      }
      _subtitleState.asmsSegmentsLoading = false;
    } catch (exception) {
      PlayerLogger.error(
        message: 'Load ASMS subtitle segments failed: $exception',
        textureId: textureId,
        error: exception,
      );
    }
  }
}
