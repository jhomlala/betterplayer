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
      List<BetterPlayerSubtitle> subtitles = List();
      for (String url in source.urls) {
        var file = File(url);
        if (file.existsSync()) {
          String fileContent = await file.readAsString();
          var subtitlesCache = _parseString(fileContent);
          subtitles.addAll(subtitlesCache);
        } else {
          print("$url doesn't exist!");
        }
      }
      return subtitles;
    } catch (exception) {
      print("Failed to read subtitles from file: $exception");
    }
    return List();
  }

  static Future<List<BetterPlayerSubtitle>> _parseSubtitlesFromNetwork(
      BetterPlayerSubtitlesSource source) async {
    try {
      var client = HttpClient();
      List<BetterPlayerSubtitle> subtitles = List();
      for (String url in source.urls) {
        var request = await client.getUrl(Uri.parse(url));
        var response = await request.close();
        var data = await response.transform(Utf8Decoder()).join();
        var cacheList = _parseString(data);
        subtitles.addAll(cacheList);
      }
      client.close();

      print("Parsed total subtitles: " + subtitles.length.toString());
      return subtitles;
    } catch (exception) {
      print("Failed to read subtitles from network: $exception");
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
      if (subtitle != null &&
          subtitle.start != null &&
          subtitle.end != null &&
          subtitle.texts != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }
}
