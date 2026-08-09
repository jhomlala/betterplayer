import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/dash/better_player_dash_utils.dart';
import 'package:better_player/src/hls/better_player_hls_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerUtils tests', () {
    test('formatBitrate formats correctly', () {
      expect(BetterPlayerUtils.formatBitrate(500), '500 bit/s');
      expect(BetterPlayerUtils.formatBitrate(1500), '~1 KBit/s');
      expect(BetterPlayerUtils.formatBitrate(2500000), '~2 MBit/s');
    });

    test('formatDuration formats correctly', () {
      expect(
        BetterPlayerUtils.formatDuration(const Duration(seconds: 5)),
        '00:05',
      );
      expect(
        BetterPlayerUtils.formatDuration(
          const Duration(minutes: 1, seconds: 30),
        ),
        '01:30',
      );
      expect(
        BetterPlayerUtils.formatDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '01:02:03',
      );
    });

    testWidgets('calculateAspectRatio returns correct value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final ratio = BetterPlayerUtils.calculateAspectRatio(context);
                expect(ratio > 0, true);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('BetterPlayerHlsUtils tests', () {
    test('parseTracks correctly parses tracks', () async {
      const data = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720
video_720p.m3u8
''';
      final tracks = await BetterPlayerHlsUtils.parseTracks(
        data,
        'https://example.com/master.m3u8',
      );
      expect(tracks.length, 2); // Default track + 720p track
      expect(tracks[1].width, 1280);
      expect(tracks[1].height, 720);
    });

    test('parseLanguages correctly parses languages', () async {
      const data = '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="English",LANGUAGE="en",URI="audio_en.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=1280000,AUDIO="audio"
video.m3u8
''';
      final audios = await BetterPlayerHlsUtils.parseLanguages(
        data,
        'https://example.com/master.m3u8',
      );
      expect(audios.length, 1);
      expect(audios[0].label, 'English');
      expect(audios[0].language, 'en');
    });
  });

  group('BetterPlayerDashUtils tests', () {
    test('parse correctly parses DASH manifest', () async {
      const data = '''
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011" profiles="urn:mpeg:dash:profile:isoff-on-demand:2011" type="static">
  <Period>
    <AdaptationSet mimeType="video/mp4">
      <Representation id="1" bandwidth="2500000" width="1920" height="1080" frameRate="30" codecs="avc1.4d401f" />
    </AdaptationSet>
    <AdaptationSet mimeType="audio/mp4" lang="en">
      <Representation id="2" bandwidth="128000" codecs="mp4a.40.2" />
    </AdaptationSet>
  </Period>
</MPD>
''';
      final holder = await BetterPlayerDashUtils.parse(
        data,
        'https://example.com/manifest.mpd',
      );
      expect(holder.tracks!.length, 1);
      expect(holder.audios!.length, 1);
      expect(holder.tracks![0].width, 1920);
      expect(holder.audios![0].language, 'en');
    });

    test('parse handles missing attributes gracefully', () async {
      const data = '''
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011">
  <Period>
    <AdaptationSet mimeType="video/mp4">
      <Representation id="1" bandwidth="2500000" />
    </AdaptationSet>
  </Period>
</MPD>
''';
      final holder = await BetterPlayerDashUtils.parse(
        data,
        'https://example.com/manifest.mpd',
      );
      expect(holder.tracks!.length, 1);
      expect(holder.tracks![0].width, 0);
    });

    test('parse correctly parses DASH subtitles', () async {
      const data = '''
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011">
  <Period>
    <AdaptationSet mimeType="text/vtt" lang="es" label="Spanish">
      <Representation id="3">
        <BaseURL>subs_es.vtt</BaseURL>
      </Representation>
    </AdaptationSet>
  </Period>
</MPD>
''';
      final holder = await BetterPlayerDashUtils.parse(
        data,
        'https://example.com/manifest.mpd',
      );
      expect(holder.subtitles!.length, 1);
      expect(holder.subtitles![0].name, 'Spanish');
      expect(holder.subtitles![0].language, 'es');
      expect(holder.subtitles![0].url, 'https://example.com/subs_es.vtt');
    });
  });
}
