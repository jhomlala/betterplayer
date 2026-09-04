import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:flutter/foundation.dart';

/// Tracks the subtitle configurations, parsing status, and rendered lines.
@immutable
class PlayerSubtitleState {
  /// Complete list of all available subtitle sources for the current media.
  final List<PlayerSubtitlesSource> subtitlesSourceList;

  /// The specific subtitle source currently active and being parsed.
  final PlayerSubtitlesSource? subtitlesSource;

  /// The parsed list of subtitle lines (start time, end time, text content).
  final List<PlayerSubtitle> subtitlesLines;

  /// The exact subtitle line that should currently be rendered on the screen.
  final PlayerSubtitle? renderedSubtitle;

  /// Flag indicating whether ASMS (HLS/DASH) segments are currently being downloaded/parsed.
  final bool asmsSegmentsLoading;

  /// A record of successfully loaded ASMS segment identifiers to prevent redundant network calls.
  final List<String> asmsSegmentsLoaded;

  const PlayerSubtitleState({
    this.subtitlesSourceList = const [],
    this.subtitlesSource,
    this.subtitlesLines = const [],
    this.renderedSubtitle,
    this.asmsSegmentsLoading = false,
    this.asmsSegmentsLoaded = const [],
  });

  PlayerSubtitleState copyWith({
    List<PlayerSubtitlesSource>? subtitlesSourceList,
    PlayerSubtitlesSource? subtitlesSource,
    List<PlayerSubtitle>? subtitlesLines,
    PlayerSubtitle? renderedSubtitle,
    bool? asmsSegmentsLoading,
    List<String>? asmsSegmentsLoaded,
    bool clearSubtitlesSource = false,
    bool clearRenderedSubtitle = false,
  }) {
    return PlayerSubtitleState(
      subtitlesSourceList: subtitlesSourceList ?? this.subtitlesSourceList,
      subtitlesSource: clearSubtitlesSource
          ? null
          : (subtitlesSource ?? this.subtitlesSource),
      subtitlesLines: subtitlesLines ?? this.subtitlesLines,
      renderedSubtitle: clearRenderedSubtitle
          ? null
          : (renderedSubtitle ?? this.renderedSubtitle),
      asmsSegmentsLoading: asmsSegmentsLoading ?? this.asmsSegmentsLoading,
      asmsSegmentsLoaded: asmsSegmentsLoaded ?? this.asmsSegmentsLoaded,
    );
  }
}
