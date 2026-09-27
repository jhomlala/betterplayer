import 'package:better_player/better_player.dart';
import 'package:better_player/src/dash/player_dash_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerDashUtils tests', () {
    test('parse identifies and parses DASH fractional frame rates', () async {
      const data = '''
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011" profiles="urn:mpeg:dash:profile:isoff-on-demand:2011" type="static">
  <Period>
    <AdaptationSet mimeType="video/mp4">
      <Representation id="1" bandwidth="100000" width="1920" height="1080" frameRate="30000/1001" codecs="avc1.4d401f" />
      <Representation id="2" bandwidth="50000" width="1280" height="720" frameRate="29.97" codecs="avc1.4d401f" />
      <Representation id="3" bandwidth="25000" width="640" height="360" frameRate="24" codecs="avc1.4d401f" />
    </AdaptationSet>
  </Period>
</MPD>
''';
      final holder = await PlayerDashUtils.parse(data, 'test.mpd');
      expect(holder.tracks != null, true);

      // Auto track + 3 video tracks
      expect(holder.tracks!.length, 4);

      final track1 = holder.tracks![1];
      expect(track1.width, 1920);
      expect(track1.height, 1080);
      expect(track1.frameRate, 30);

      final track2 = holder.tracks![2];
      expect(track2.width, 1280);
      expect(track2.height, 720);
      expect(track2.frameRate, 30);

      final track3 = holder.tracks![3];
      expect(track3.width, 640);
      expect(track3.height, 360);
      expect(track3.frameRate, 24);
    });

    test('parse identifies and parses DASH audio tracks', () async {
      const data = '''
<MPD>
  <Period>
    <AdaptationSet mimeType="audio/mp4" lang="en" label="English">
      <Representation id="audio-en" bandwidth="128000" />
    </AdaptationSet>
    <AdaptationSet mimeType="audio/mp4" lang="fr">
      <Representation id="audio-fr" bandwidth="128000" />
    </AdaptationSet>
  </Period>
</MPD>
''';
      final holder = await PlayerDashUtils.parse(data, 'test.mpd');
      expect(holder.audios != null, true);
      expect(holder.audios!.length, 2);

      final audio1 = holder.audios![0];
      expect(audio1.label, 'English');
      expect(audio1.language, 'en');
      expect(audio1.mimeType, 'audio/mp4');

      final audio2 = holder.audios![1];
      expect(audio2.label, 'fr'); // Fallback to lang if label is null
      expect(audio2.language, 'fr');
    });

    test(
      'parse identifies and parses DASH subtitle tracks with BaseURL',
      () async {
        const data = '''
<MPD>
  <Period>
    <AdaptationSet mimeType="text/vtt" lang="en" label="English Subs">
      <Representation id="sub-en">
        <BaseURL>subs/en.vtt</BaseURL>
      </Representation>
    </AdaptationSet>
  </Period>
</MPD>
''';
        final holder = await PlayerDashUtils.parse(
          data,
          'https://example.com/stream/test.mpd',
        );
        expect(holder.subtitles != null, true);
        expect(holder.subtitles!.length, 1);

        final sub = holder.subtitles![0];
        expect(sub.name, 'English Subs');
        expect(sub.language, 'en');
        expect(sub.mimeType, 'text/vtt');
        expect(sub.url, 'https://example.com/stream/subs/en.vtt');
      },
    );

    test('parse handles missing attributes gracefully', () async {
      const data = '''
<MPD>
  <Period>
    <AdaptationSet mimeType="video/mp4">
      <Representation id="1" />
      <Representation id="2" bandwidth="" width="" height="" frameRate="" />
    </AdaptationSet>
  </Period>
</MPD>
''';
      final holder = await PlayerDashUtils.parse(data, 'test.mpd');
      expect(holder.tracks != null, true);
      expect(holder.tracks!.length, 3); // Auto + 2 tracks

      final track1 = holder.tracks![1];
      expect(track1.width, 0);
      expect(track1.height, 0);
      expect(track1.bitrate, 0);
      expect(track1.frameRate, 0);

      final track2 = holder.tracks![2];
      expect(track2.width, 0);
      expect(track2.height, 0);
      expect(track2.bitrate, 0);
      expect(track2.frameRate, 0);
    });

    test('parse handles malformed XML gracefully', () async {
      const data =
          '<MPD><Period><AdaptationSet mimeType="video/mp4"'; // Unclosed tags
      final holder = await PlayerDashUtils.parse(data, 'test.mpd');
      expect(holder.tracks, isEmpty);
      expect(holder.audios, isEmpty);
      expect(holder.subtitles, isEmpty);
    });

    test(
      'parse identifies tracks when AdaptationSet uses contentType or child mimeType',
      () async {
        const data = '''
<MPD>
  <Period>
    <AdaptationSet contentType="video">
      <Representation id="v1" bandwidth="100000" width="1920" height="1080" codecs="avc1.4d401f" />
    </AdaptationSet>
    <AdaptationSet contentType="audio" lang="en" label="English">
      <Representation id="a1" bandwidth="128000" />
    </AdaptationSet>
    <AdaptationSet lang="es" label="Spanish Subs">
      <Representation id="s1" mimeType="text/vtt">
        <BaseURL>subs/es.vtt</BaseURL>
      </Representation>
    </AdaptationSet>
  </Period>
</MPD>
''';
        final holder = await PlayerDashUtils.parse(
          data,
          'https://example.com/stream/test.mpd',
        );
        expect(holder.tracks, hasLength(2));
        expect(holder.tracks![1].width, 1920);
        expect(holder.audios, hasLength(1));
        expect(holder.audios![0].language, 'en');
        expect(holder.subtitles, hasLength(1));
        expect(holder.subtitles![0].language, 'es');
        expect(holder.subtitles![0].mimeType, 'text/vtt');
      },
    );

    test(
      'parse extracts video, audio, and subtitle tracks when only child Representation has mimeType',
      () async {
        const data = '''
<MPD>
  <Period>
    <AdaptationSet>
      <Representation id="v1" mimeType="video/mp4" bandwidth="2500000" width="1280" height="720" frameRate="60000/1001" codecs="avc1.64001f" />
      <Representation id="v2" mimeType="video/mp4" bandwidth="5000000" width="1920" height="1080" frameRate="60" codecs="avc1.640028" />
    </AdaptationSet>
    <AdaptationSet lang="de" segmentAlignment="true">
      <Representation id="a-de" mimeType="audio/mp4" bandwidth="192000" />
    </AdaptationSet>
    <AdaptationSet lang="ja" label="Japanese" segmentAlignment="true">
      <Representation id="s-ja" mimeType="text/x-ssa">
        <BaseURL>https://cdn.example.com/subs/ja.ssa</BaseURL>
      </Representation>
    </AdaptationSet>
  </Period>
</MPD>
''';
        final holder = await PlayerDashUtils.parse(
          data,
          'https://example.com/live/manifest.mpd',
        );

        expect(holder.tracks, hasLength(3));
        expect(holder.tracks![1].id, 'v1');
        expect(holder.tracks![1].frameRate, 60);
        expect(holder.tracks![2].id, 'v2');
        expect(holder.tracks![2].width, 1920);

        expect(holder.audios, hasLength(1));
        expect(holder.audios![0].id, 0);
        expect(holder.audios![0].language, 'de');
        expect(holder.audios![0].label, 'de');
        expect(holder.audios![0].mimeType, 'audio/mp4');
        expect(holder.audios![0].segmentAlignment, isTrue);

        expect(holder.subtitles, hasLength(1));
        expect(holder.subtitles![0].language, 'ja');
        expect(holder.subtitles![0].name, 'Japanese');
        expect(holder.subtitles![0].mimeType, 'text/x-ssa');
        expect(holder.subtitles![0].segmentAlignment, isTrue);
        expect(
          holder.subtitles![0].url,
          'https://cdn.example.com/subs/ja.ssa',
        );
      },
    );

    test(
      'parse ignores AdaptationSet with unsupported contentType or no mimeType anywhere',
      () async {
        const data = '''
<MPD>
  <Period>
    <AdaptationSet contentType="image">
      <Representation id="thumb1" bandwidth="10000" width="320" height="180" />
    </AdaptationSet>
    <AdaptationSet>
      <Representation id="unknown" />
    </AdaptationSet>
    <AdaptationSet />
  </Period>
</MPD>
''';
        final holder = await PlayerDashUtils.parse(
          data,
          'https://example.com/stream/test.mpd',
        );
        expect(holder.tracks, isEmpty);
        expect(holder.audios, isEmpty);
        expect(holder.subtitles, isEmpty);
      },
    );

    test(
      'parse handles contentType="text" subtitles with protocol-relative and missing BaseURL',
      () async {
        const data = '''
<MPD>
  <Period>
    <AdaptationSet contentType="text" lang="it">
      <Representation id="s-it">
        <BaseURL>//subs.example.com/it.vtt</BaseURL>
      </Representation>
    </AdaptationSet>
    <AdaptationSet contentType="text" lang="pt">
      <Representation id="s-pt" />
    </AdaptationSet>
  </Period>
</MPD>
''';
        final holder = await PlayerDashUtils.parse(
          data,
          'https://example.com/stream/test.mpd',
        );
        expect(holder.subtitles, hasLength(2));
        expect(holder.subtitles![0].name, 'it');
        expect(holder.subtitles![0].url, 'https://subs.example.com/it.vtt');
        expect(holder.subtitles![1].name, 'pt');
        expect(holder.subtitles![1].url, isNull);
        expect(holder.subtitles![1].realUrls, ['']);
      },
    );
  });
}
