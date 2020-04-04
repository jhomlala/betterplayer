import 'dart:convert';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source.dart';

import 'better_player_subtitle.dart';
import 'better_player_subtitles_source_type.dart';

class BetterPlayerSubtitlesFactory {
  static Future<List<BetterPlayerSubtitle>> parseSubtitles(
      BetterPlayerSubtitlesSource source) async {
    assert(source != null);
    switch (source.type) {
      case BetterPlayerSubtitlesSourceType.FILE:
        return await _parseSubtitlesFromFile(source);
      case BetterPlayerSubtitlesSourceType.NETWORK:
        return await _parseSubtitlesFromNetwork(source);
      case BetterPlayerSubtitlesSourceType.MEMORY:
        return _parseSubtitlesFromMemory(source);
      default:
        return List();
    }
  }

  static Future<List<BetterPlayerSubtitle>> _parseSubtitlesFromFile(
      BetterPlayerSubtitlesSource source) async {
    try {
      var file = File(source.url);
      if (file.existsSync()) {
        String fileContent = await file.readAsString();
        if (fileContent?.isNotEmpty == true) {
          return _parseString(fileContent);
        }
      } else {
        print("${source.url} doesn't exist!");
      }
    } catch (exception) {
      print("Failed to read subtitles from file: ${source.url}: $exception");
    }
    return List();
  }

  static Future<List<BetterPlayerSubtitle>> _parseSubtitlesFromNetwork(
      BetterPlayerSubtitlesSource source) async {
    try {
      var client = HttpClient();
      var request = await client.getUrl(Uri.parse(source.url));
      var response = await request.close();
      var data = await response.transform(Utf8Decoder()).join();

      if (data?.isNotEmpty == true) {
        return _parseString(data);
      }
    } catch (exception) {
      print("Failed to read subtitles from network: ${source.url}: $exception");
    }
    return List();
  }

  static List<BetterPlayerSubtitle> _parseSubtitlesFromMemory(
      BetterPlayerSubtitlesSource source) {
    try {
      return _parseString(source.content);
    } catch (exception) {
      print("Failed to read subtitles from memory: $exception");
    }
    return List();
  }

  static List<BetterPlayerSubtitle> _parseString(String value) {
    assert(value != null);

    List<String> components = value.split('\r\n\r\n');
    if (components.length == 1) {
      components = value.split('\n\n');
    }

    final List<BetterPlayerSubtitle> subtitlesObj = List();

    for (var component in components) {
      if (component.isEmpty) {
        continue;
      }

      final subtitle = BetterPlayerSubtitle(component);
      if (subtitle != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }
}
