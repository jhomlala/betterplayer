import 'package:better_player/better_player.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:better_player/src/utils/better_player_io_utils.dart';
import 'package:http/http.dart' as http;

class PlayerSubtitlesFactory {
  PlayerSubtitlesFactory({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<List<PlayerSubtitle>> parseSubtitles(
    PlayerSubtitlesSource source,
  ) async {
    switch (source.type) {
      case PlayerSubtitlesSourceType.file:
        return _parseSubtitlesFromFile(source);
      case PlayerSubtitlesSourceType.network:
        return _parseSubtitlesFromNetwork(source);
      case PlayerSubtitlesSourceType.memory:
        return _parseSubtitlesFromMemory(source);
      default:
        return [];
    }
  }

  Future<List<PlayerSubtitle>> _parseSubtitlesFromFile(
    PlayerSubtitlesSource source,
  ) async {
    try {
      final subtitles = <PlayerSubtitle>[];
      for (final url in source.urls!) {
        final filePath = url!;
        if (BetterPlayerIoUtils.fileExists(filePath)) {
          final fileContent = await BetterPlayerIoUtils.readFileAsString(
            filePath,
          );
          final subtitlesCache = _parseString(fileContent);
          subtitles.addAll(subtitlesCache);
        } else {
          PlayerLogger.warning(message: "$url doesn't exist!");
        }
      }
      return subtitles;
    } catch (exception) {
      PlayerLogger.error(
        message: 'Failed to read subtitles from file: $exception',
        error: exception,
      );
    }
    return [];
  }

  Future<List<PlayerSubtitle>> _parseSubtitlesFromNetwork(
    PlayerSubtitlesSource source,
  ) async {
    try {
      final subtitles = <PlayerSubtitle>[];
      for (final url in source.urls!) {
        final nonNullHeaders = <String, String>{};
        if (source.headers != null) {
          source.headers!.forEach((key, value) {
            nonNullHeaders[key] = value;
          });
        }
        final response = await _httpClient.get(
          Uri.parse(url!),
          headers: nonNullHeaders.isEmpty ? null : nonNullHeaders,
        );
        final data = response.body;
        final cacheList = _parseString(data);
        subtitles.addAll(cacheList);
      }

      PlayerLogger.debug(
        message: 'Parsed total subtitles: ${subtitles.length}',
      );
      return subtitles;
    } catch (exception) {
      PlayerLogger.error(
        message: 'Failed to read subtitles from network: $exception',
        error: exception,
      );
    }
    return [];
  }

  List<PlayerSubtitle> _parseSubtitlesFromMemory(
    PlayerSubtitlesSource source,
  ) {
    try {
      return _parseString(source.content!);
    } catch (exception) {
      PlayerLogger.error(
        message: 'Failed to read subtitles from memory: $exception',
        error: exception,
      );
    }
    return [];
  }

  List<PlayerSubtitle> _parseString(String value) {
    // 1. Handle UTF-8 BOM
    var content = value;
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    // 2. Normalize line endings (CRLF -> LF, CR -> LF)
    content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 3. Parse X-TIMESTAMP-MAP
    var timestampOffset = Duration.zero;
    final lines = content.split('\n');
    final cueLines = <String>[];
    var isWebVTT = false;

    for (final line in lines) {
      if (line.trim().startsWith('WEBVTT')) {
        isWebVTT = true;
        continue;
      }
      if (line.trim().startsWith('X-TIMESTAMP-MAP=')) {
        timestampOffset = _parseTimestampMap(line.trim());
        continue;
      }
      // Skip NOTE, REGION, STYLE blocks or comments
      if (line.trim().startsWith('NOTE') ||
          line.trim().startsWith('REGION') ||
          line.trim().startsWith('STYLE')) {
        continue;
      }
      cueLines.add(line);
    }

    // Rejoin and split by double newlines for cues
    final normalizedContent = cueLines.join('\n');
    final components = normalizedContent.split('\n\n');

    // Skip parsing files with no cues
    if (components.length <= 1 && !isWebVTT) {
      // Check if it's single cue or split by single newline if needed
    }

    final subtitlesObj = <PlayerSubtitle>[];

    for (final component in components) {
      if (component.trim().isEmpty) {
        continue;
      }
      final subtitle = PlayerSubtitle(component, isWebVTT, timestampOffset);
      if (subtitle.start != null &&
          subtitle.end != null &&
          subtitle.texts != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }

  Duration _parseTimestampMap(String line) {
    // Example: X-TIMESTAMP-MAP=MPEGTS:900000, LOCAL:00:00:20.000
    try {
      final parts = line.replaceFirst('X-TIMESTAMP-MAP=', '').split(',');
      String? mpegtsStr;
      String? localStr;

      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('MPEGTS:')) {
          mpegtsStr = trimmed.replaceFirst('MPEGTS:', '');
        } else if (trimmed.startsWith('LOCAL:')) {
          localStr = trimmed.replaceFirst('LOCAL:', '');
        }
      }

      var localDuration = Duration.zero;
      if (localStr != null) {
        localDuration = PlayerSubtitle.stringToDuration(localStr);
      }

      if (mpegtsStr != null) {
        final mpegtsValue = int.tryParse(mpegtsStr) ?? 0;
        // MPEG-TS timestamps are 90kHz clock. Also account for 33-bit rollover (2^33 = 8589934592)
        final rolloverCount = mpegtsValue ~/ 8589934592;
        final adjustedMpegts = mpegtsValue % 8589934592;
        final mpegtsDuration =
            Duration(milliseconds: adjustedMpegts * 1000 ~/ 90000) +
            Duration(
              milliseconds: rolloverCount * 8589934592 * 1000 ~/ 90000,
            );

        return localDuration - mpegtsDuration;
      }

      return localDuration;
    } catch (exception) {
      PlayerLogger.warning(message: 'Failed to parse X-TIMESTAMP-MAP: $line');
      return Duration.zero;
    }
  }
}
