import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/hls/hls_parser/conent_types.dart';
import 'package:better_player/src/hls/hls_parser/mime_types.dart';
import 'package:xml/xml.dart';

import '../../better_player.dart';

///DASH helper class
class BetterPlayerDashUtils {
  static Future<BetterPlayerAsmsDataHolder> parse(
    String data,
    String masterPlaylistUrl,
  ) async {
    List<BetterPlayerAsmsTrack> tracks = [];
    final List<BetterPlayerAsmsAudioTrack> audios = [];
    final List<BetterPlayerAsmsSubtitle> subtitles = [];
    try {
      final document = XmlDocument.parse(data);
      final adaptationSets = document.findAllElements('AdaptationSet');
      for (final XmlElement node in adaptationSets) {
        try {
          final mimeType = node.getAttribute('mimeType');
          final contentType = node.getAttribute('contentType');

          if ((mimeType == null || mimeType.isEmpty) && (contentType == null || contentType.isEmpty)) {
            continue;
          }

          if (MimeTypes.isVideo(mimeType) || ContentTypes.isVideo(contentType)) {
            tracks = tracks + parseVideo(node);
          } else if (MimeTypes.isAudio(mimeType) || ContentTypes.isAudio(contentType)) {
            final parsedAudio = parseAudio(node, audios.length);
            if (parsedAudio != null) {
              audios.add(parsedAudio);
            }
          } else if (MimeTypes.isText(mimeType) || ContentTypes.isText(contentType)) {
            final sub = parseSubtitle(masterPlaylistUrl, node);
            if (sub != null) {
              subtitles.add(sub);
            }
          }
        } catch (e) {
          BetterPlayerUtils.log("Exception on dash parse node: $node\n$e");
        }
      }
    } catch (exception) {
      BetterPlayerUtils.log("Exception on dash parse: $exception");
    }
    return BetterPlayerAsmsDataHolder(tracks: tracks, audios: audios, subtitles: subtitles);
  }

  static List<BetterPlayerAsmsTrack> parseVideo(XmlElement node) {
    final List<BetterPlayerAsmsTrack> tracks = [];

    final representations = node.findAllElements('Representation');

    for (final representation in representations) {
      final String? id = representation.getAttribute('id');
      if (id == null || id.isEmpty) continue;

      final int width = int.parse(representation.getAttribute('width') ?? '0');
      final int height = int.parse(representation.getAttribute('height') ?? '0');
      final int bitrate = int.parse(representation.getAttribute('bandwidth') ?? '0');
      final int frameRate = int.parse(representation.getAttribute('frameRate') ?? '0');
      final String? codecs = representation.getAttribute('codecs');
      final String? mimeType = MimeTypes.getMediaMimeType(codecs ?? '');

      tracks.add(BetterPlayerAsmsTrack(id, width, height, bitrate, frameRate, codecs, mimeType));
    }

    return tracks;
  }

  static BetterPlayerAsmsAudioTrack? parseAudio(XmlElement node, int index) {
    final String? language = node.getAttribute('lang');
    final String? mimeType = node.getAttribute('mimeType');

    if ((language == null || language.isEmpty) && (mimeType == null || mimeType.isEmpty)) return null;

    final String segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    String? label = node.getAttribute('label');

    label ??= language;

    return BetterPlayerAsmsAudioTrack(
        id: index,
        segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
        label: label,
        language: language,
        mimeType: mimeType);
  }

  static BetterPlayerAsmsSubtitle? parseSubtitle(String masterPlaylistUrl, XmlElement node) {
    String? url = node.getElement('Representation')?.getElement('BaseURL')?.text;

    if (url == null || url.isEmpty) return null;

    final String segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    String? name = node.getAttribute('label');
    final String? language = node.getAttribute('lang');
    final String? mimeType = node.getAttribute('mimeType');

    if (!url.contains("http")) {
      final Uri masterPlaylistUri = Uri.parse(masterPlaylistUrl);
      final pathSegments = <String>[...masterPlaylistUri.pathSegments];
      pathSegments[pathSegments.length - 1] = url;
      url = Uri(
              scheme: masterPlaylistUri.scheme,
              host: masterPlaylistUri.host,
              port: masterPlaylistUri.port,
              pathSegments: pathSegments)
          .toString();
    }

    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    name ??= language;

    return BetterPlayerAsmsSubtitle(
        name: name,
        language: language,
        mimeType: mimeType,
        segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
        url: url,
        realUrls: [url ?? '']);
  }
}
