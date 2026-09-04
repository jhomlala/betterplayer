import 'dart:convert';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:http/http.dart' as http;

class PlayerSubtitlesFactory {
  static Future<List<PlayerSubtitle>> parseSubtitles(
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

  static Future<List<PlayerSubtitle>> _parseSubtitlesFromFile(
    PlayerSubtitlesSource source,
  ) async {
    try {
      final subtitles = <PlayerSubtitle>[];
      for (final url in source.urls!) {
        final file = File(url!);
        if (file.existsSync()) {
          final fileContent = await file.readAsString();
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

  static Future<List<PlayerSubtitle>> _parseSubtitlesFromNetwork(
    PlayerSubtitlesSource source,
  ) async {
    try {
      final client = http.Client();
      final subtitles = <PlayerSubtitle>[];
      for (final url in source.urls!) {
        final nonNullHeaders = <String, String>{};
        if (source.headers != null) {
          source.headers!.forEach((key, value) {
            if (value != null) {
              nonNullHeaders[key] = value;
            }
          });
        }
        final response = await client.get(
          Uri.parse(url!),
          headers: nonNullHeaders.isEmpty ? null : nonNullHeaders,
        );
        final data = response.body;
        final cacheList = _parseString(data);
        subtitles.addAll(cacheList);
      }
      client.close();

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

  static List<PlayerSubtitle> _parseSubtitlesFromMemory(
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

  static List<PlayerSubtitle> _parseString(String value) {
    var components = value.split('\r\n\r\n');
    if (components.length == 1) {
      components = value.split('\n\n');
    }

    // Skip parsing files with no cues
    if (components.length == 1) {
      return [];
    }

    final subtitlesObj = <PlayerSubtitle>[];

    final isWebVTT = components.contains('WEBVTT');
    for (final component in components) {
      if (component.isEmpty) {
        continue;
      }
      final subtitle = PlayerSubtitle(component, isWebVTT);
      if (subtitle.start != null &&
          subtitle.end != null &&
          subtitle.texts != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }
}
