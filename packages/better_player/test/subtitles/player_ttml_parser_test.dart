import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/player_subtitles_factory.dart';
import 'package:better_player/src/subtitles/player_ttml_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('PlayerTtmlParser tests', () {
    const parser = PlayerTtmlParser();

    test('Parse Issue #1213 EZConvert TTML sample', () {
      const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xml:lang="en-US" xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" xmlns:ttm="http://www.w3.org/ns/ttml#metadata" ttp:frameRate="24" ttp:frameRateMultiplier="1000 1001" ttp:profile="http://www.w3.org/ns/ttml/profile/imsc1/text" ttp:timeBase="media">
  <head>
    <metadata/>
    <styling>
      <style xml:id="style.center" tts:fontFamily="Arial" tts:fontSize="100%" tts:fontStyle="normal" tts:fontWeight="normal" tts:backgroundColor="transparent" tts:color="white" tts:textAlign="center"/>
    </styling>
    <layout>
      <region xml:id="region.after" tts:displayAlign="after" tts:backgroundColor="transparent" tts:origin="10% 10%" tts:extent="80% 80%"/>
      <region xml:id="region.before" tts:displayAlign="before" tts:backgroundColor="transparent" tts:origin="10% 10%" tts:extent="80% 80%"/>
    </layout>
  </head>
  <body>
    <div>
      <p style="style.center" region="region.after" begin="00:00:03:12" end="00:00:12:00">Only one or two short samples are needed<br/>to make sure the conversion basically works</p>
      <p style="style.center" region="region.before" begin="00:00:14:09" end="00:00:25:17">Cool, got it, will do it by end of next week.</p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(content: ttml);
      expect(cues.length, 2);

      // Cue 1:
      // 12 frames at 23.976 fps = 500.5 ms -> 3500ms
      expect(cues[0].index, 1);
      expect(cues[0].start!.inMilliseconds, 3500);
      expect(cues[0].end!.inMilliseconds, 12000);
      expect(cues[0].alignment, Alignment.bottomCenter);
      expect(cues[0].texts!.length, 2);
      expect(
        cues[0].texts![0],
        '<font color="white">Only one or two short samples are needed</font>',
      );
      expect(
        cues[0].texts![1],
        '<font color="white">to make sure the conversion basically works</font>',
      );

      // Cue 2:
      // 9 frames at 23.976 fps = 375 ms -> 14375ms
      // 17 frames at 23.976 fps = 709 ms -> 25709ms
      expect(cues[1].index, 2);
      expect(cues[1].start!.inMilliseconds, 14375);
      expect(cues[1].end!.inMilliseconds, 25709);
      expect(cues[1].alignment, Alignment.topCenter);
      expect(cues[1].texts!.length, 1);
      expect(
        cues[1].texts![0],
        '<font color="white">Cool, got it, will do it by end of next week.</font>',
      );
    });

    test('Parse clock-time with fraction and timecount formats', () {
      const ttml = '''
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:01:02.500" end="00:01:05.800">Clock time cue</p>
      <p begin="10s" dur="4.5s">Timecount seconds with dur</p>
      <p begin="500ms" end="1500ms">Timecount milliseconds</p>
      <p begin="1.5m" end="2m">Timecount minutes</p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(content: ttml);
      expect(cues.length, 4);

      // Cue 1
      expect(
        cues[0].start,
        const Duration(minutes: 1, seconds: 2, milliseconds: 500),
      );
      expect(
        cues[0].end,
        const Duration(minutes: 1, seconds: 5, milliseconds: 800),
      );
      expect(cues[0].texts, ['Clock time cue']);

      // Cue 2
      expect(cues[1].start, const Duration(seconds: 10));
      expect(cues[1].end, const Duration(milliseconds: 14500));
      expect(cues[1].texts, ['Timecount seconds with dur']);

      // Cue 3
      expect(cues[2].start, const Duration(milliseconds: 500));
      expect(cues[2].end, const Duration(milliseconds: 1500));
      expect(cues[2].texts, ['Timecount milliseconds']);

      // Cue 4
      expect(cues[3].start, const Duration(seconds: 90));
      expect(cues[3].end, const Duration(minutes: 2));
      expect(cues[3].texts, ['Timecount minutes']);
    });

    test('Parse inline spans with bold, italic, underline, and color', () {
      const ttml = '''
<tt xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">
        This is <span tts:fontWeight="bold">bold</span> and <span tts:color="#FF0000">red</span> and <span tts:fontStyle="italic">italic</span> text.
      </p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(content: ttml);
      expect(cues.length, 1);
      expect(
        cues[0].texts![0],
        'This is <b>bold</b> and <font color="#FF0000">red</font> and <i>italic</i> text.',
      );
    });

    test('Parse style inheritance and region alignments', () {
      const ttml = '''
<tt xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling">
  <head>
    <styling>
      <style xml:id="base" tts:color="yellow" tts:fontWeight="bold"/>
      <style xml:id="derived" style="base" tts:fontStyle="italic"/>
      <style xml:id="rightAlign" tts:textAlign="right"/>
    </styling>
    <layout>
      <region xml:id="topRight" tts:displayAlign="before" style="rightAlign"/>
      <region xml:id="centerRegion" tts:displayAlign="center" tts:textAlign="center"/>
    </layout>
  </head>
  <body>
    <div>
      <p style="derived" region="topRight" begin="00:00:01.000" end="00:00:04.000">
        Top right derived style
      </p>
      <p region="centerRegion" begin="00:00:05.000" end="00:00:08.000">
        Center region
      </p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(content: ttml);
      expect(cues.length, 2);

      // Cue 1 has top right alignment, bold, italic, yellow
      expect(cues[0].alignment, Alignment.topRight);
      expect(
        cues[0].texts![0],
        '<font color="yellow"><u><i><b>Top right derived style</b></i></u></font>'
            .replaceAll('<u>', '')
            .replaceAll('</u>', ''),
      );

      // Cue 2 has center alignment
      expect(cues[1].alignment, Alignment.center);
    });

    test('Gracefully handle malformed or empty TTML', () {
      expect(parser.parse(content: ''), isEmpty);
      expect(parser.parse(content: 'Not XML at all'), isEmpty);
      expect(
        parser.parse(
          content: '<?xml version="1.0"?><root><p>No tt tag</p></root>',
        ),
        isEmpty,
      );
      expect(
        parser.parse(
          content:
              '<tt><body><p begin="00:00:05" end="00:00:02">Invalid duration</p></body></tt>',
        ),
        isEmpty,
      );
    });

    test(
      'PlayerSubtitlesFactory auto-detects and parses TTML from memory',
      () async {
        final factory = PlayerSubtitlesFactory();
        const ttml = '''
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:03.000">TTML from factory</p>
    </div>
  </body>
</tt>
''';

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          content: ttml,
        );

        final subtitles = await factory.parseSubtitles(source);
        expect(subtitles.length, 1);
        expect(subtitles[0].texts![0], 'TTML from factory');
        expect(subtitles[0].start, const Duration(seconds: 1));
        expect(subtitles[0].end, const Duration(seconds: 3));
      },
    );

    test('Inherits region, style, and begin offset from ancestor div', () {
      const ttml = '''
<tt xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling">
  <head>
    <styling>
      <style xml:id="divStyle" tts:color="cyan" tts:fontWeight="bold"/>
    </styling>
    <layout>
      <region xml:id="topCenter" tts:displayAlign="before" tts:textAlign="center"/>
    </layout>
  </head>
  <body>
    <div region="topCenter" style="divStyle" begin="10s">
      <p begin="2s" dur="3s">Inherited from div</p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(content: ttml);
      expect(cues.length, 1);
      expect(cues[0].start, const Duration(seconds: 12));
      expect(cues[0].end, const Duration(seconds: 15));
      expect(cues[0].alignment, Alignment.topCenter);
      expect(
        cues[0].texts![0],
        '<font color="cyan"><b>Inherited from div</b></font>',
      );
    });

    test(
      'PlayerSubtitlesFactory discriminates WebVTT containing tt tags',
      () async {
        final factory = PlayerSubtitlesFactory();
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:03.000
<tt>Teletype text</tt>
''';

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          content: vtt,
        );

        final subtitles = await factory.parseSubtitles(source);
        expect(subtitles.length, 1);
        expect(subtitles[0].texts![0], '<tt>Teletype text</tt>');
      },
    );

    test(
      'PlayerSubtitlesFactory parses TTML with XML comments containing arrows',
      () async {
        final factory = PlayerSubtitlesFactory();
        const ttmlWithComments = '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Created by SubtitleEdit 3.6.0 -->
<!-- Arrow indicator comment: 00:00:01.000 --> 00:00:03.000 -->
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:03.000">Subtitle with comment</p>
    </div>
  </body>
</tt>
''';

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          content: ttmlWithComments,
        );

        final subtitles = await factory.parseSubtitles(source);
        expect(subtitles.length, 1);
        expect(subtitles[0].texts![0], 'Subtitle with comment');
      },
    );

    test(
      'PlayerTtmlParser preserves paragraph color on mixed lines starting with span',
      () {
        const parser = PlayerTtmlParser();
        const ttml = '''
<tt xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:04.000" tts:color="red">
        <span tts:color="blue">Blue prefix</span> and red suffix
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(content: ttml);
        expect(cues.length, 1);
        expect(
          cues[0].texts![0],
          '<font color="red"><font color="blue">Blue prefix</font> and red suffix</font>',
        );
      },
    );

    test('PlayerTtmlParser inherits styles from root tt element', () {
      const parser = PlayerTtmlParser();
      const ttml = '''
<tt xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling" tts:color="magenta">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:04.000">Inherited from root tt</p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(content: ttml);
      expect(cues.length, 1);
      expect(
        cues[0].texts![0],
        '<font color="magenta">Inherited from root tt</font>',
      );
    });
  });
}
