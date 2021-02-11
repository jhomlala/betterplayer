// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/hls/better_player_hls_audio_track.dart';

// Project imports:
import 'package:better_player/src/hls/better_player_hls_subtitle.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:better_player/src/hls/hls_parser/hls_master_playlist.dart';
import 'package:better_player/src/hls/hls_parser/hls_media_playlist.dart';
import 'package:better_player/src/hls/hls_parser/hls_playlist_parser.dart';
import 'package:better_player/src/hls/hls_parser/rendition.dart';
import 'package:better_player/src/hls/hls_parser/segment.dart';

///HLS helper class
class BetterPlayerHlsUtils {
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);
  static final HlsPlaylistParser _hlsPlaylistParser =
      HlsPlaylistParser.create();

  static Future<List<BetterPlayerHlsTrack>> parseTracks(
      String data, String masterPlaylistUrl) async {
    assert(data != null, "Data can't be null");
    final List<BetterPlayerHlsTrack> tracks = [];
    try {
      final parsedPlaylist = await HlsPlaylistParser.create()
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
      BetterPlayerUtils.log("Exception on parseSubtitles: $exception");
    }
    return tracks;
  }

  ///Parse subtitles from provided m3u8 url
  static Future<List<BetterPlayerHlsSubtitle>> parseSubtitles(
      String data, String masterPlaylistUrl) async {
    assert(data != null, "Data can't be null");
    assert(masterPlaylistUrl != null, "MasterPlaylistUrl can't be null");

    final List<BetterPlayerHlsSubtitle> subtitles = [];
    try {
      final parsedPlaylist = await HlsPlaylistParser.create()
          .parseString(Uri.parse(masterPlaylistUrl), data);
      if (parsedPlaylist is HlsMasterPlaylist) {
        for (final Rendition element in parsedPlaylist.subtitles) {
          final hlsSubtitle = await _parseSubtitlesPlaylist(element);
          if (hlsSubtitle != null) {
            subtitles.add(hlsSubtitle);
          }
        }
      }
    } catch (exception) {
      BetterPlayerUtils.log("Exception on parseSubtitles: $exception");
    }

    return subtitles;
  }

  static Future<BetterPlayerHlsSubtitle> _parseSubtitlesPlaylist(
      Rendition rendition) async {
    assert(rendition != null, "Rendition can't be null");
    try {
      final subtitleData = await getDataFromUrl(rendition.url.toString());
      final parsedSubtitle =
          await _hlsPlaylistParser.parseString(rendition.url, subtitleData);
      final hlsMediaPlaylist = parsedSubtitle as HlsMediaPlaylist;
      final hlsSubtitlesUrls = <String>[];

      for (final Segment segment in hlsMediaPlaylist.segments) {
        final split = rendition.url.toString().split("/");
        var realUrl = "";
        for (var index = 0; index < split.length - 1; index++) {
          // ignore: use_string_buffers
          realUrl += "${split[index]}/";
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
      BetterPlayerUtils.log("Failed to process subtitles playlist: $exception");
      return null;
    }
  }

  static Future<List<BetterPlayerHlsAudioTrack>> parseLanguages(
      String data, String masterPlaylistUrl) async {
    assert(data != null, "Data can't be null");
    assert(masterPlaylistUrl != null, "MasterPlaylistUrl can't be null");
    final List<BetterPlayerHlsAudioTrack> audios = [];
    final parsedPlaylist = await HlsPlaylistParser.create()
        .parseString(Uri.parse(masterPlaylistUrl), data);
    if (parsedPlaylist is HlsMasterPlaylist) {
      for (int index = 0; index < parsedPlaylist.audios.length; index++) {
        final Rendition audio = parsedPlaylist.audios[index];
        audios.add(BetterPlayerHlsAudioTrack(
          id: index,
          label: audio.name,
          language: audio.format.language,
          url: audio.url.toString(),
        ));
      }
    }

    return audios;
  }

  static Future<String> getDataFromUrl(String url) async {
    try {
      assert(url != null, "Url can't be null!");
      final request = await _httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      var data = "";
      await response.transform(const Utf8Decoder()).listen((contents) {
        data += contents.toString();
      }).asFuture<String>();

      return data;
    } catch (exception) {
      BetterPlayerUtils.log("GetDataFromUrl failed: $exception");
      return null;
    }
  }
}
