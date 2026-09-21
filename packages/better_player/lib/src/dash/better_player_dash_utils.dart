import 'package:better_player/better_player.dart';
import 'package:better_player/src/hls/hls_parser/mime_types.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:xml/xml.dart';

///DASH helper class
class BetterPlayerDashUtils {
  static Future<PlayerAsmsDataHolder> parse(
    String data,
    String masterPlaylistUrl,
  ) async {
    var tracks = <PlayerAsmsTrack>[];
    final audios = <PlayerAsmsAudioTrack>[];
    final subtitles = <PlayerAsmsSubtitle>[];
    try {
      var audiosCount = 0;
      final document = XmlDocument.parse(data);
      final adaptationSets = document.findAllElements('AdaptationSet');
      for (final node in adaptationSets) {
        final mimeType = node.getAttribute('mimeType');

        if (mimeType != null) {
          if (MimeTypes.isVideo(mimeType)) {
            tracks = tracks + parseVideo(node);
          } else if (MimeTypes.isAudio(mimeType)) {
            audios.add(parseAudio(node, audiosCount));
            audiosCount += 1;
          } else if (MimeTypes.isText(mimeType)) {
            subtitles.add(parseSubtitle(masterPlaylistUrl, node));
          }
        }
      }
    } catch (exception) {
      PlayerLogger.error(
        message: 'Exception on dash parse: $exception',
        error: exception,
      );
    }
    if (tracks.isNotEmpty) {
      tracks.insert(0, PlayerAsmsTrack.defaultTrack());
    }
    return PlayerAsmsDataHolder(
      tracks: tracks,
      audios: audios,
      subtitles: subtitles,
    );
  }

  static List<PlayerAsmsTrack> parseVideo(XmlElement node) {
    final tracks = <PlayerAsmsTrack>[];

    final representations = node.findAllElements('Representation');

    for (final representation in representations) {
      final id = representation.getAttribute('id');
      final width =
          int.tryParse(representation.getAttribute('width') ?? '0') ?? 0;
      final height =
          int.tryParse(representation.getAttribute('height') ?? '0') ?? 0;
      final bitrate =
          int.tryParse(
            representation.getAttribute('bandwidth') ?? '0',
          ) ??
          0;

      var frameRate = 0;
      final frameRateAttribute = representation.getAttribute('frameRate');
      if (frameRateAttribute != null) {
        if (frameRateAttribute.contains('/')) {
          final parts = frameRateAttribute.split('/');
          final numerator = double.tryParse(parts[0]) ?? 0.0;
          final denominator = double.tryParse(parts[1]) ?? 1.0;
          if (denominator > 0) {
            frameRate = (numerator / denominator).round();
          }
        } else {
          frameRate = (double.tryParse(frameRateAttribute) ?? 0.0).round();
        }
      }

      final codecs = representation.getAttribute('codecs');
      final mimeType = MimeTypes.getMediaMimeType(codecs ?? '');
      tracks.add(
        PlayerAsmsTrack(
          id,
          width,
          height,
          bitrate,
          frameRate,
          codecs,
          mimeType,
        ),
      );
    }

    return tracks;
  }

  static PlayerAsmsAudioTrack parseAudio(XmlElement node, int index) {
    final segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    var label = node.getAttribute('label');
    final language = node.getAttribute('lang');
    final mimeType = node.getAttribute('mimeType');

    label ??= language;

    return PlayerAsmsAudioTrack(
      id: index,
      segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
      label: label,
      language: language,
      mimeType: mimeType,
    );
  }

  static PlayerAsmsSubtitle parseSubtitle(
    String masterPlaylistUrl,
    XmlElement node,
  ) {
    final segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    var name = node.getAttribute('label');
    final language = node.getAttribute('lang');
    final mimeType = node.getAttribute('mimeType');
    var url = node.getElement('Representation')?.getElement('BaseURL')?.text;
    if (url?.contains('http') == false) {
      final masterPlaylistUri = Uri.parse(masterPlaylistUrl);
      url = masterPlaylistUri.resolve(url!).toString();
    }

    if (url != null && url.startsWith('//')) {
      url = 'https:$url';
    }

    name ??= language;

    return PlayerAsmsSubtitle(
      name: name,
      language: language,
      mimeType: mimeType,
      segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
      url: url,
      realUrls: [url ?? ''],
    );
  }
}
