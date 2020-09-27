import 'dart:convert';
import 'dart:io';

import 'package:better_player/src/hls/better_player_hls_subtitle.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';

///HLS helper class
class BetterPlayerHlsUtils {
  static HttpClient _httpClient = HttpClient()
    ..connectionTimeout = Duration(seconds: 5);
  static HlsPlaylistParser _hlsPlaylistParser = HlsPlaylistParser.create();

  static Future<List<BetterPlayerHlsTrack>> parseTracks(
      String masterPlaylistUrl) async {
    assert(masterPlaylistUrl != null, "MasterPlaylistUrl can't be null");
    List<BetterPlayerHlsTrack> tracks = List();
    try {
      String data = await _getDataFromUrl(masterPlaylistUrl);
      var parsedPlaylist = await HlsPlaylistParser.create()
          .parseString(Uri.parse(masterPlaylistUrl), data);
      if (parsedPlaylist is HlsMasterPlaylist) {
        parsedPlaylist.variants.forEach(
          (variant) {
            tracks.add(BetterPlayerHlsTrack(variant.format.width,
                variant.format.height, variant.format.bitrate));
          },
        );
      }
    } catch (exception) {
      print("Exception on parseSubtitles: " + exception.toString());
    }
    return tracks;
  }

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
            var hlsSubtitle = await _parseSubtitlesPlaylist(element);
            if (hlsSubtitle != null) {
              subtitles.add(hlsSubtitle);
            }
          }
        }
      }
    } catch (exception) {
      print("Exception on parseSubtitles: " + exception.toString());
    }

    return subtitles;
  }

  static Future<BetterPlayerHlsSubtitle> _parseSubtitlesPlaylist(
      Rendition rendition) async {
    assert(rendition != null, "Rendition can't be null");
    try {
      var subtitleData = await _getDataFromUrl(rendition.url.toString());
      var parsedSubtitle =
          await _hlsPlaylistParser.parseString(rendition.url, subtitleData);
      var hlsMediaPlaylist = parsedSubtitle as HlsMediaPlaylist;
      var hlsSubtitlesUrls = List<String>();

      for (Segment segment in hlsMediaPlaylist.segments) {
        var split = rendition.url.toString().split("/");
        var realUrl = "";
        for (var index = 0; index < split.length - 1; index++) {
          realUrl += split[index] + "/";
        }
        realUrl += segment.url;
        hlsSubtitlesUrls.add(realUrl);
      }
      return BetterPlayerHlsSubtitle(
          name: rendition.format.label,
          language: rendition.format.language,
          url: rendition.url.toString(),
          realUrls: hlsSubtitlesUrls);
    } catch (exception) {
      print("Failed to process subtitles playlist: " + exception.toString());
      return null;
    }
  }

  static Future<String> _getDataFromUrl(String url) async {
    try {
      assert(url != null, "Url can't be null!");
      var request = await _httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      var data = "";
      await response.transform(Utf8Decoder()).listen((contents) {
        data = contents.toString();
      }).asFuture();
      return data;
    } catch (exception) {
      print("GetDataFromUrl failed: " + exception.toString());
      return null;
    }
  }
}
