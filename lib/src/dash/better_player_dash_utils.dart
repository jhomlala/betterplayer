// Dart imports:
import 'dart:convert';
import 'dart:io';

// External Package imports:
import 'package:better_player/src/asms/better_player_asms_data_holder.dart';
import 'package:better_player/src/hls/hls_parser/mime_types.dart';
import 'package:xml/xml.dart';

// Package imports:
import 'package:better_player/src/core/better_player_utils.dart';

// Project imports:
import 'package:better_player/src/asms/better_player_asms_audio_track.dart';
import 'package:better_player/src/asms/better_player_asms_subtitle.dart';
import 'package:better_player/src/asms/better_player_asms_track.dart';

///DASH helper class
class BetterPlayerDashUtils {
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);

  static Future<BetterPlayerAsmsDataHolder> parse(
      String data, String masterPlaylistUrl) async {
    final document = XmlDocument.parse(data);
    final adaptationSets = document.findAllElements('AdaptationSet');
    List<BetterPlayerAsmsTrack> tracks = [];
    List<BetterPlayerAsmsAudioTrack> audios = [];
    List<BetterPlayerAsmsSubtitle> subtitles = [];
    int audiosCount = 0;
    adaptationSets.forEach((node) {
      final mimeType = node.getAttribute('mimeType');
      if (mimeType != null) {
        if (MimeTypes.isVideo(mimeType)) {
          tracks = tracks + parseVideo(node);
        } else if (MimeTypes.isAudio(mimeType)) {
          audios.add(parseAudio(node, audiosCount));
          audiosCount += 1;
        } else if (MimeTypes.isText(mimeType)) {
          subtitles.add(parseSubtitle(node));
        }
      }
    });
    return BetterPlayerAsmsDataHolder(tracks: tracks, audios: audios, subtitles: subtitles);
  }

  static List<BetterPlayerAsmsTrack> parseVideo(XmlElement node) {
    List<BetterPlayerAsmsTrack> tracks = [];

    final representations = node.findAllElements('Representation');

    representations.forEach((representation) {
      final String? id = representation.getAttribute('id');
      final int width = int.parse(representation.getAttribute('width') ?? '0');
      final int height = int.parse(representation.getAttribute('height') ?? '0');
      final int bitrate = int.parse(representation.getAttribute('bandwidth') ?? '0');
      final int frameRate = int.parse(representation.getAttribute('frameRate') ?? '0');
      final String? codecs = representation.getAttribute('codecs');
      print("codes: "+(codecs ?? ''));
      final String? mimeType = MimeTypes.getMediaMimeType(codecs ?? '');
      print("mimeType: "+(mimeType ?? ''));
      tracks.add(BetterPlayerAsmsTrack(id, width, height, bitrate, frameRate, codecs, mimeType));
    });

    return tracks;
  }

  static BetterPlayerAsmsAudioTrack parseAudio(XmlElement node, int index) {
    String segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    String? label = node.getAttribute('label');
    String? language = node.getAttribute('lang');
    String? mimeType = node.getAttribute('mimeType');

    if (label == null) {
      label = language;
    }

    return BetterPlayerAsmsAudioTrack(
      id: index,
      segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
      label: label,
      language: language,
      mimeType: mimeType
    );
  }

  static BetterPlayerAsmsSubtitle parseSubtitle(XmlElement node) {
    String segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    String? name = node.getAttribute('label');
    String? language = node.getAttribute('lang');
    String? mimeType = node.getAttribute('mimeType');
    String? url = node.getElement('Representation')?.getElement('BaseURL')?.text;
    if (url != null && url.startsWith('//')) {
      url = 'https:' + url;
    }

    if (name == null) {
      name = language;
    }

    return BetterPlayerAsmsSubtitle(
      name: name,
      language: language,
      mimeType: mimeType,
      segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
      url: url
    );
  }

  static Future<String?> getDataFromUrl(String url,
      [Map<String, String?>? headers]) async {
    try {
      final request = await _httpClient.getUrl(Uri.parse(url));
      if (headers != null) {
        headers.forEach((name, value) => request.headers.add(name, value!));
      }

      final response = await request.close();
      var data = "";
      await response.transform(const Utf8Decoder()).listen((content) {
        data += content.toString();
      }).asFuture<String?>();

      return data;
    } catch (exception) {
      BetterPlayerUtils.log("GetDataFromUrl failed: $exception");
      return null;
    }
  }

}
