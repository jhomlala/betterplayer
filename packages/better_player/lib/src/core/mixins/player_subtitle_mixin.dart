part of '../better_player_controller.dart';

extension PlayerSubtitleExtension on BetterPlayerController {
  ///Configure subtitles based on subtitles source.
  void _setupSubtitles() {
    _betterPlayerSubtitlesSourceList.add(
      PlayerSubtitlesSource(type: PlayerSubtitlesSourceType.none),
    );
    final defaultSubtitle = _betterPlayerSubtitlesSourceList.firstWhereOrNull(
      (element) => element.selectedByDefault == true,
    );

    ///Setup subtitles (none is default)
    setupSubtitleSource(
      defaultSubtitle ?? _betterPlayerSubtitlesSourceList.last,
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
    _betterPlayerSubtitlesSource = subtitlesSource;
    subtitlesLines.clear();
    _asmsSegmentsLoaded.clear();
    _asmsSegmentsLoading = false;

    if (subtitlesSource.type != PlayerSubtitlesSourceType.none) {
      if (subtitlesSource.asmsIsSegmented == true) {
        return;
      }
      final subtitlesParsed = await PlayerSubtitlesFactory.parseSubtitles(
        subtitlesSource,
      );
      subtitlesLines.addAll(subtitlesParsed);
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
      if (_asmsSegmentsLoading) {
        return;
      }
      _asmsSegmentsLoading = true;
      final source = _betterPlayerSubtitlesSource;
      final loadDurationEnd = Duration(
        milliseconds:
            position.inMilliseconds +
            5 * (_betterPlayerSubtitlesSource?.asmsSegmentsTime ?? 5000),
      );

      final segmentsToLoad = _betterPlayerSubtitlesSource?.asmsSegments
          ?.where((segment) {
            return segment.endTime > position &&
                segment.startTime < loadDurationEnd &&
                !_asmsSegmentsLoaded.contains(segment.realUrl);
          })
          .map((segment) => segment.realUrl)
          .toList();

      if (segmentsToLoad != null && segmentsToLoad.isNotEmpty) {
        final subtitlesParsed = await PlayerSubtitlesFactory.parseSubtitles(
          PlayerSubtitlesSource(
            type: _betterPlayerSubtitlesSource!.type,
            headers: _betterPlayerSubtitlesSource!.headers,
            urls: segmentsToLoad,
          ),
        );

        ///Additional check if current source of subtitles is same as source
        ///used to start loading subtitles. It can be different when user
        ///changes subtitles and there was already pending load.
        if (source == _betterPlayerSubtitlesSource) {
          subtitlesLines.addAll(subtitlesParsed);
          _asmsSegmentsLoaded.addAll(segmentsToLoad);
        }
      }
      _asmsSegmentsLoading = false;
    } catch (exception) {
      PlayerLogger.error(
        message: 'Load ASMS subtitle segments failed: $exception',
        textureId: textureId,
        error: exception,
      );
    }
  }
}
