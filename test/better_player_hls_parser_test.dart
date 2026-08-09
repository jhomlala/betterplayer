import 'package:better_player/src/hls/hls_parser/hls_master_playlist.dart';
import 'package:better_player/src/hls/hls_parser/hls_media_playlist.dart';
import 'package:better_player/src/hls/hls_parser/hls_playlist_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HlsPlaylistParser tests', () {
    test('Parse master playlist', () async {
      const masterPlaylist = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720,CODECS="avc1.42e01e,mp4a.40.2"
video_720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2560000,RESOLUTION=1920x1080,CODECS="avc1.4d401f,mp4a.40.2"
video_1080p.m3u8
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
        Uri.parse('https://example.com/master.m3u8'),
        masterPlaylist,
      );

      expect(playlist is HlsMasterPlaylist, true);
      final master = playlist as HlsMasterPlaylist;
      expect(master.variants.length, 2);
      expect(master.variants[0].format.width, 1280);
      expect(master.variants[0].format.height, 720);
      expect(
        master.variants[0].url.toString(),
        'https://example.com/video_720p.m3u8',
      );
    });

    test('Parse media playlist', () async {
      const mediaPlaylist = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:10.0,
segment1.ts
#EXTINF:10.0,
segment2.ts
#EXT-X-ENDLIST
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
        Uri.parse('https://example.com/video.m3u8'),
        mediaPlaylist,
      );

      expect(playlist is HlsMediaPlaylist, true);
      final media = playlist as HlsMediaPlaylist;
      expect(media.segments.length, 2);
      expect(media.targetDurationUs, 10000000);
      expect(media.segments[0].durationUs, 10000000);
      expect(media.segments[0].url, 'segment1.ts');
    });

    test('Parse master playlist with media tags', () async {
      const masterPlaylist = '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="English",DEFAULT=YES,AUTOSELECT=YES,LANGUAGE="en",URI="audio_en.m3u8"
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT=YES,AUTOSELECT=YES,FORCED=NO,LANGUAGE="en",URI="subs_en.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=1280000,CODECS="avc1.42e01e,mp4a.40.2",AUDIO="audio",SUBTITLES="subs"
video.m3u8
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
        Uri.parse('https://example.com/master.m3u8'),
        masterPlaylist,
      );

      expect(playlist is HlsMasterPlaylist, true);
      final master = playlist as HlsMasterPlaylist;
      expect(master.audios.length, 1);
      expect(master.subtitles.length, 1);
      expect(master.audios[0].name, 'English');
      expect(master.subtitles[0].name, 'English');
    });

    test('Parse invalid playlist should throw exception', () async {
      const invalidPlaylist = 'NOT A PLAYLIST';
      final parser = HlsPlaylistParser.create();
      expect(
        () => parser.parseString(
          Uri.parse('https://example.com/invalid.m3u8'),
          invalidPlaylist,
        ),
        throwsException,
      );
    });

    test('Parse master playlist with session keys', () async {
      const masterPlaylist = '''
#EXTM3U
#EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.widevine",URI="data:text/plain;base64,AAAAPXBzc2gAAAAA7e+LqXnWSs6jyC5jhNZmXQAAAB0iBy9uZXRmbGl4EgVub3JtYVoDbm9ybVoAbm9ybQ=="
#EXT-X-STREAM-INF:BANDWIDTH=1280000
video.m3u8
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
          Uri.parse('https://example.com/master.m3u8'), masterPlaylist);

      expect(playlist is HlsMasterPlaylist, true);
      final master = playlist as HlsMasterPlaylist;
      expect(master.sessionKeyDrmInitData.length, 1);
    });

    test('Parse media playlist with encryption tags', () async {
      const mediaPlaylist = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXT-X-KEY:METHOD=AES-128,URI="https://priv.example.com/key.php?r=52"
#EXTINF:10.0,
segment1.ts
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
          Uri.parse('https://example.com/video.m3u8'), mediaPlaylist);

      expect(playlist is HlsMediaPlaylist, true);
      final media = playlist as HlsMediaPlaylist;
      expect(media.segments[0].fullSegmentEncryptionKeyUri,
          'https://priv.example.com/key.php?r=52');
    });

    test('Parse media playlist with init segment', () async {
      const mediaPlaylist = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXT-X-MAP:URI="init.mp4",BYTERANGE="1000@0"
#EXTINF:10.0,
segment1.ts
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
          Uri.parse('https://example.com/video.m3u8'), mediaPlaylist);

      expect(playlist is HlsMediaPlaylist, true);
      final media = playlist as HlsMediaPlaylist;
      expect(media.segments[0].initializationSegment?.url, 'init.mp4');
      expect(media.segments[0].initializationSegment?.byterangeLength, 1000);
    });

    test('Parse media playlist with discontinuity', () async {
      const mediaPlaylist = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:10.0,
segment1.ts
#EXT-X-DISCONTINUITY
#EXTINF:10.0,
segment2.ts
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
          Uri.parse('https://example.com/video.m3u8'), mediaPlaylist);

      final media = playlist as HlsMediaPlaylist;
      expect(media.segments[1].relativeDiscontinuitySequence, 1);
    });

    test('Parse master playlist with variable definitions', () async {
      const masterPlaylist = '''
#EXTM3U
#EXT-X-DEFINE:NAME="URL",VALUE="video.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=1280000
{\$URL}
''';
      final parser = HlsPlaylistParser.create();
      final playlist = await parser.parseString(
          Uri.parse('https://example.com/master.m3u8'), masterPlaylist);

      final master = playlist as HlsMasterPlaylist;
      expect(master.variants[0].url.toString(), 'https://example.com/video.m3u8');
    });
  });
}
