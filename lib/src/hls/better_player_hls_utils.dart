import 'dart:convert';
import 'dart:io';

import 'package:better_player/src/hls/better_player_hls_subtitle.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';

///HLS helper class
class BetterPlayerHlsUtils {
  static HttpClient _httpClient = HttpClient()
    ..connectionTimeout = Duration(seconds: 5);
  static HlsPlaylistParser _hlsPlaylistParser = HlsPlaylistParser.create();

  ///Parse subtitles from provided m3u8 url
  static Future<List<BetterPlayerHlsSubtitle>> parseSubtitles(
      String masterPlaylistUrl) async {
    assert(masterPlaylistUrl != null, "MasterPlaylistUrl can't be null");
    List<BetterPlayerHlsSubtitle> subtitles = List();
    try {
      String data = await _getDataFromUrl(masterPlaylistUrl);
      if (data != null) {
        var parsedPlaylist = await HlsPlaylistParser.create()
            .parseString(Uri.parse(masterPlaylistUrl), data);
        if (parsedPlaylist is HlsMasterPlaylist) {
          for (Rendition element in parsedPlaylist.subtitles) {
            var subtitleData = await _getDataFromUrl(element.url.toString());
            var parsedSubtitle =
                await _hlsPlaylistParser.parseString(element.url, subtitleData);
            var hlsMediaPlaylist = parsedSubtitle as HlsMediaPlaylist;
            var hlsSubtitlesUrls = List<String>();

            for (Segment segment in hlsMediaPlaylist.segments) {
              print("Segment url: " + segment.url.toString());
              var split = element.url.toString().split("/");
              var realUrl = "";
              for (var index = 0; index < split.length - 1; index++) {
                realUrl += split[index] + "/";
              }
              realUrl += segment.url;
              hlsSubtitlesUrls.add(realUrl);
            }
            print("Real urls: " + hlsSubtitlesUrls.toString());
            subtitles.add(
              BetterPlayerHlsSubtitle(
                  name: element.format.label,
                  language: element.format.language,
                  url: element.url.toString(),
                  realUrls: hlsSubtitlesUrls),
            );
          }
        }
      }
    } catch (exception) {
      print("Exception on parseSubtitles: " + exception);
    }

    return subtitles;
  }

  static Future<String> _getDataFromUrl(String url) async {
    try {
      var request = await _httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      var data = "";
      await response.transform(Utf8Decoder()).listen((contents) {
        data = contents.toString();
      }).asFuture();
      return data;
    } catch (exception) {
      print("GetDataFromUrl failed: " + exception);
      return null;
    }
  }
}
