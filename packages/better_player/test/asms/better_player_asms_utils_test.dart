import 'package:better_player/src/asms/better_player_asms_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('BetterPlayerAsmsUtils tests', () {
    test('isDataSourceHls identifies HLS', () {
      final utils = BetterPlayerAsmsUtils();
      expect(utils.isDataSourceHls('test.m3u8'), true);
      expect(utils.isDataSourceHls('test.mp4'), false);
    });

    test('isDataSourceDash identifies DASH', () {
      final utils = BetterPlayerAsmsUtils();
      expect(utils.isDataSourceDash('test.mpd'), true);
      expect(utils.isDataSourceDash('test.mp4'), false);
    });

    test('isDataSourceAsms identifies ASMS', () {
      final utils = BetterPlayerAsmsUtils();
      expect(utils.isDataSourceAsms('test.m3u8'), true);
      expect(utils.isDataSourceAsms('test.mpd'), true);
      expect(utils.isDataSourceAsms('test.mp4'), false);
    });

    test('parse identifies and parses HLS', () async {
      final utils = BetterPlayerAsmsUtils();
      const data = '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1280000\nvideo.m3u8';
      final holder = await utils.parse(data, 'test.m3u8');
      expect(holder.tracks != null, true);
    });

    test('parse identifies and parses DASH', () async {
      final utils = BetterPlayerAsmsUtils();
      const data =
          '<MPD xmlns="urn:mpeg:dash:schema:mpd:2011" profiles="urn:mpeg:dash:profile:isoff-on-demand:2011" type="static"><Period></Period></MPD>';
      final holder = await utils.parse(data, 'test.mpd');
      expect(holder.tracks != null, true);
    });

    test('getDataFromUrl fetches data', () async {
      final utils = BetterPlayerAsmsUtils(
        httpClient: MockClient((request) async {
          return http.Response('test data', 200);
        }),
      );
      final data = await utils.getDataFromUrl(
        'https://example.com/test.m3u8',
      );
      expect(data, 'test data');
    });

    test('getDataFromUrl with headers', () async {
      final utils = BetterPlayerAsmsUtils(
        httpClient: MockClient((request) async {
          if (request.headers['Authorization'] == 'Bearer test') {
            return http.Response('test data', 200);
          }
          return http.Response('', 401);
        }),
      );

      final data = await utils.getDataFromUrl(
        'https://example.com/test.m3u8',
        {'Authorization': 'Bearer test'},
      );
      expect(data, 'test data');
    });
  });
}
