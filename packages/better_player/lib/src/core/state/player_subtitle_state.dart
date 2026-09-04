import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';

/// Tracks the subtitle configurations, parsing status, and rendered lines.
class PlayerSubtitleState {
  /// Complete list of all available subtitle sources for the current media.
  final List<PlayerSubtitlesSource> subtitlesSourceList = [];

  /// The specific subtitle source currently active and being parsed.
  PlayerSubtitlesSource? subtitlesSource;

  /// The parsed list of subtitle lines (start time, end time, text content).
  List<PlayerSubtitle> subtitlesLines = [];

  /// The exact subtitle line that should currently be rendered on the screen.
  PlayerSubtitle? renderedSubtitle;

  /// Flag indicating whether ASMS (HLS/DASH) segments are currently being downloaded/parsed.
  bool asmsSegmentsLoading = false;

  /// A record of successfully loaded ASMS segment identifiers to prevent redundant network calls.
  final List<String> asmsSegmentsLoaded = [];
}
