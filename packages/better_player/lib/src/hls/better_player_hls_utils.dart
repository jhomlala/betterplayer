import 'package:better_player/better_player.dart';
import 'package:better_player/src/hls/hls_parser/hls_master_playlist.dart';
import 'package:better_player/src/hls/hls_parser/hls_media_playlist.dart';
import 'package:better_player/src/hls/hls_parser/hls_playlist_parser.dart';
import 'package:better_player/src/hls/hls_parser/rendition.dart';
import 'package:better_player/src/hls/hls_parser/util.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';

///HLS helper class
class BetterPlayerHlsUtils {
  static Future<PlayerAsmsDataHolder> parse(
    String data,
    String masterPlaylistUrl,
  ) async {
    var tracks = <PlayerAsmsTrack>[];
    var subtitles = <PlayerAsmsSubtitle>[];
    var audios = <PlayerAsmsAudioTrack>[];
    try {
      final list = await Future.wait([
        parseTracks(data, masterPlaylistUrl),
        parseSubtitles(data, masterPlaylistUrl),
        parseLanguages(data, masterPlaylistUrl),
      ]);
      tracks = list[0] as List<PlayerAsmsTrack>;
      subtitles = list[1] as List<PlayerAsmsSubtitle>;
      audios = list[2] as List<PlayerAsmsAudioTrack>;
    } catch (exception, stackTrace) {
      BetterPlayerLogger.instance.error(
        'Exception on hls parse: $exception',
        error: exception,
        stackTrace: stackTrace,
        breadcrumb: 'HLS',
      );
    }
    return PlayerAsmsDataHolder(
      tracks: tracks,
      audios: audios,
      subtitles: subtitles,
    );
  }

  static Future<List<PlayerAsmsTrack>> parseTracks(
    String data,
    String masterPlaylistUrl,
  ) async {
    final tracks = <PlayerAsmsTrack>[];
    try {
      final parsedPlaylist = await HlsPlaylistParser.create().parseString(
        Uri.parse(masterPlaylistUrl),
        data,
      );
      if (parsedPlaylist is HlsMasterPlaylist) {
        for (final variant in parsedPlaylist.variants) {
          tracks.add(
            PlayerAsmsTrack(
              '',
              variant.format.width,
              variant.format.height,
              variant.format.bitrate,
              0,
              '',
              '',
            ),
          );
        }
      }

      if (tracks.isNotEmpty) {
        tracks.insert(0, PlayerAsmsTrack.defaultTrack());
      }
    } catch (exception, stackTrace) {
      BetterPlayerLogger.instance.error(
        'Exception on parseSubtitles: $exception',
        error: exception,
        stackTrace: stackTrace,
        breadcrumb: 'HLS',
      );
    }
    return tracks;
  }

  ///Parse subtitles from provided m3u8 url
  static Future<List<PlayerAsmsSubtitle>> parseSubtitles(
    String data,
    String masterPlaylistUrl,
  ) async {
    final subtitles = <PlayerAsmsSubtitle>[];
    try {
      final parsedPlaylist = await HlsPlaylistParser.create().parseString(
        Uri.parse(masterPlaylistUrl),
        data,
      );

      if (parsedPlaylist is HlsMasterPlaylist) {
        for (final element in parsedPlaylist.subtitles) {
          final hlsSubtitle = await _parseSubtitlesPlaylist(element);
          if (hlsSubtitle != null) {
            subtitles.add(hlsSubtitle);
          }
        }
      }
    } catch (exception, stackTrace) {
      BetterPlayerLogger.instance.error(
        'Exception on parseSubtitles: $exception',
        error: exception,
        stackTrace: stackTrace,
        breadcrumb: 'HLS',
      );
    }

    return subtitles;
  }

  ///Parse HLS subtitles playlist. If subtitles are segmented (more than 1
  ///segment is present in playlist), then setup subtitles as segmented.
  ///Segmented subtitles are loading with JIT policy, when video is playing
  ///to prevent massive load od video start. Segmented subtitles will have
  ///filled segments list which contains start, end and url of subtitles based
  ///on time in playlist.
  static Future<PlayerAsmsSubtitle?> _parseSubtitlesPlaylist(
    Rendition rendition,
  ) async {
    try {
      final hlsPlaylistParser = HlsPlaylistParser.create();
      final subtitleData = await BetterPlayerAsmsUtils.getDataFromUrl(
        rendition.url.toString(),
      );
      if (subtitleData == null) {
        return null;
      }

      final parsedSubtitle = await hlsPlaylistParser.parseString(
        rendition.url,
        subtitleData,
      );
      final hlsMediaPlaylist = parsedSubtitle as HlsMediaPlaylist;
      final hlsSubtitlesUrls = <String>[];

      final asmsSegments = <PlayerAsmsSubtitleSegment>[];
      final isSegmented = hlsMediaPlaylist.segments.length > 1;
      var microSecondsFromStart = 0;
      for (final segment in hlsMediaPlaylist.segments) {
        final split = rendition.url.toString().split('/');
        var realUrl = '';
        for (var index = 0; index < split.length - 1; index++) {
          // ignore: use_string_buffers
          realUrl += '${split[index]}/';
        }
        if (segment.url?.startsWith('http') == true) {
          realUrl = segment.url!;
        } else {
          realUrl += segment.url!;
        }
        hlsSubtitlesUrls.add(realUrl);

        if (isSegmented) {
          final nextMicroSecondsFromStart =
              microSecondsFromStart + segment.durationUs!;
          asmsSegments.add(
            PlayerAsmsSubtitleSegment(
              Duration(microseconds: microSecondsFromStart),
              Duration(microseconds: nextMicroSecondsFromStart),
              realUrl,
            ),
          );
          microSecondsFromStart = nextMicroSecondsFromStart;
        }
      }

      var targetDuration = 0;
      if (parsedSubtitle.targetDurationUs != null) {
        targetDuration = parsedSubtitle.targetDurationUs! ~/ 1000;
      }

      var isDefault = false;

      if (rendition.format.selectionFlags != null) {
        isDefault = Util.checkBitPositionIsSet(
          rendition.format.selectionFlags!,
          1,
        );
      }

      return PlayerAsmsSubtitle(
        name: rendition.format.label,
        language: rendition.format.language,
        url: rendition.url.toString(),
        realUrls: hlsSubtitlesUrls,
        isSegmented: isSegmented,
        segmentsTime: targetDuration,
        segments: asmsSegments,
        isDefault: isDefault,
      );
    } catch (exception, stackTrace) {
      BetterPlayerLogger.instance.error(
        'Failed to process subtitles playlist: $exception',
        error: exception,
        stackTrace: stackTrace,
        breadcrumb: 'HLS',
      );
      return null;
    }
  }

  static Future<List<PlayerAsmsAudioTrack>> parseLanguages(
    String data,
    String masterPlaylistUrl,
  ) async {
    final audios = <PlayerAsmsAudioTrack>[];
    final parsedPlaylist = await HlsPlaylistParser.create().parseString(
      Uri.parse(masterPlaylistUrl),
      data,
    );
    if (parsedPlaylist is HlsMasterPlaylist) {
      for (var index = 0; index < parsedPlaylist.audios.length; index++) {
        final audio = parsedPlaylist.audios[index];
        audios.add(
          PlayerAsmsAudioTrack(
            id: index,
            label: audio.name,
            language: audio.format.language,
            url: audio.url?.toString(),
          ),
        );
      }
    }

    return audios;
  }
}
