import 'package:better_player/src/subtitles/webvtt_inline_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('WebVttInlineParser Edge Cases Tests', () {
    test('Nested tags and hierarchy ordering', () {
      const input =
          '<b>Bold <i>Italic <u>Underline</u> Still Italic</i> Still Bold</b>';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );

      expect(span.children, isNotEmpty);
      expect(span.children!.length, 5);

      // 'Bold '
      final span1 = span.children![0] as TextSpan;
      expect(span1.text, 'Bold ');
      expect(span1.style!.fontWeight, FontWeight.bold);
      expect(span1.style!.fontStyle, isNot(FontStyle.italic));

      // 'Italic '
      final span2 = span.children![1] as TextSpan;
      expect(span2.text, 'Italic ');
      expect(span2.style!.fontWeight, FontWeight.bold);
      expect(span2.style!.fontStyle, FontStyle.italic);
      expect(span2.style!.decoration, isNot(TextDecoration.underline));

      // 'Underline'
      final span3 = span.children![2] as TextSpan;
      expect(span3.text, 'Underline');
      expect(span3.style!.fontWeight, FontWeight.bold);
      expect(span3.style!.fontStyle, FontStyle.italic);
      expect(span3.style!.decoration, TextDecoration.underline);

      // ' Still Italic'
      final span4 = span.children![3] as TextSpan;
      expect(span4.text, ' Still Italic');
      expect(span4.style!.fontWeight, FontWeight.bold);
      expect(span4.style!.fontStyle, FontStyle.italic);
      expect(span4.style!.decoration, isNot(TextDecoration.underline));

      // ' Still Bold'
      final span5 = span.children![4] as TextSpan;
      expect(span5.text, ' Still Bold');
      expect(span5.style!.fontWeight, FontWeight.bold);
      expect(span5.style!.fontStyle, isNot(FontStyle.italic));
    });

    test('Malformed and unbalanced tags handling', () {
      const input = '<b>Hello <i>World';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      expect(span.children, isNotEmpty);

      final lastSpan = span.children!.last as TextSpan;
      expect(lastSpan.text, 'World');
      expect(lastSpan.style!.fontWeight, FontWeight.bold);
      expect(lastSpan.style!.fontStyle, FontStyle.italic);
    });

    test('Overlapping malformed tags handling', () {
      const input = '<b>Hello <i>World</b>/No Bold Inside Italic?</i>';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      expect(span.children, isNotEmpty);
    });

    test('Color class tags and case sensitivity', () {
      const input = '<c.RED>Red Text</c.RED><c.blue>Blue Text</c.blue>';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      expect(span.children!.length, 2);

      final redSpan = span.children![0] as TextSpan;
      expect(redSpan.text, 'Red Text');
      expect(redSpan.style!.color, Colors.red);

      final blueSpan = span.children![1] as TextSpan;
      expect(blueSpan.text, 'Blue Text');
      expect(blueSpan.style!.color, Colors.blue);
    });

    test('Font tag with variable whitespaces and quotes', () {
      const input =
          '<font   color  =  "yellow" >Yellow</font><font color=\x27cyan\x27>Cyan</font>';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      expect(span.children!.length, 2);

      final yellowSpan = span.children![0] as TextSpan;
      expect(yellowSpan.text, 'Yellow');
      expect(yellowSpan.style!.color, Colors.yellow);

      final cyanSpan = span.children![1] as TextSpan;
      expect(cyanSpan.text, 'Cyan');
      expect(cyanSpan.style!.color, Colors.cyan);
    });

    test('Unknown color values fallback gracefully', () {
      const input = '<font color="unknownColor">Fallback</font>';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      final textSpan = span.children![0] as TextSpan;
      expect(textSpan.text, 'Fallback');
      expect(textSpan.style!.color, null);
    });

    test('Exhaustive HTML entity decoding', () {
      const input = 'Entities: &amp; &lt; &gt; &nbsp; &lrm; &rlm;';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      expect(span.toPlainText(), 'Entities: & < > \u00A0 \u200E \u200F');
    });

    test('Self closing break tags and line breaks', () {
      const input = 'Line1<br>Line2<br/>Line3';
      final span = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      expect(span.children!.length, 5);

      expect((span.children![0] as TextSpan).text, 'Line1');
      expect((span.children![1] as TextSpan).text, '\n');
      expect((span.children![2] as TextSpan).text, 'Line2');
      expect((span.children![3] as TextSpan).text, '\n');
      expect((span.children![4] as TextSpan).text, 'Line3');
    });
  });
}
