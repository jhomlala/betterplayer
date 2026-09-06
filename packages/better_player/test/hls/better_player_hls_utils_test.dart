import 'package:better_player/src/asms/better_player_asms_utils.dart';
import 'package:better_player/src/hls/better_player_hls_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BetterPlayerHlsUtils advanced tests', () {
    setUp(() {
      BetterPlayerAsmsUtils.httpClient = null;
    });

    test('parseSubtitles handles segmented subtitles', () async {
      BetterPlayerAsmsUtils.httpClient = MockClient((request) async {
        return http.Response('''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:10.0,
segment1.vtt
#EXTINF:10.0,
segment2.vtt
''', 200);
      });

      const masterData = '''
#EXTM3U
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",URI="subs.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=1280000,SUBTITLES="subs"
video.m3u8
''';
      final subtitles = await BetterPlayerHlsUtils.parseSubtitles(
        masterData,
        'https://example.com/master.m3u8',
      );

      expect(subtitles.length, 1);
      expect(subtitles[0].name, 'English');
      expect(subtitles[0].isSegmented, true);
      expect(subtitles[0].segments?.length, 2);
      expect(subtitles[0].segments?[0].startTime, Duration.zero);
      expect(
        subtitles[0].segments?[0].endTime,
        const Duration(seconds: 10),
      );
      expect(
        subtitles[0].segments?[1].startTime,
        const Duration(seconds: 10),
      );
      expect(
        subtitles[0].segments?[1].endTime,
        const Duration(seconds: 20),
      );
    });
  });
}
