import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/player_subtitles_factory.dart';
import 'package:better_player_example/pages/subtitles_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Better Player Example TTML Subtitles Tests', () {
    test(
      'Load and parse example_subtitles.ttml asset with PlayerSubtitlesFactory',
      () async {
        String ttmlContent;
        try {
          ttmlContent = await rootBundle.loadString(
            'assets/example_subtitles.ttml',
          );
        } catch (_) {
          ttmlContent = await File(
            'packages/better_player_example/assets/example_subtitles.ttml',
          ).readAsString();
        }

        expect(ttmlContent, isNotEmpty);
        expect(ttmlContent, contains('<tt'));

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          content: ttmlContent,
          name: 'TTML Subtitles',
        );

        final factory = PlayerSubtitlesFactory();
        final subtitles = await factory.parseSubtitles(source);

        expect(subtitles.length, 3);

        // Cue 1:
        // Welcome to TTML Subtitles! (yellow text, bottom center)
        expect(subtitles[0].start, Duration.zero);
        expect(subtitles[0].end, const Duration(seconds: 3));
        expect(subtitles[0].alignment, Alignment.bottomCenter);
        expect(
          subtitles[0].texts![0],
          contains('<font color="yellow"><b>TTML</b></font>'),
        );

        // Cue 2:
        // Top-aligned subtitle with italic and green text.
        expect(subtitles[1].start, const Duration(seconds: 3));
        expect(subtitles[1].end, const Duration(milliseconds: 6500));
        expect(subtitles[1].alignment, Alignment.topCenter);
        expect(subtitles[1].texts![0], contains('<i>italic</i>'));
        expect(
          subtitles[1].texts![0],
          contains('<font color="#00FF00">green</font>'),
        );

        // Cue 3:
        // Multi-line support with line break (<br/>).
        expect(subtitles[2].start, const Duration(milliseconds: 6500));
        expect(subtitles[2].end, const Duration(seconds: 10));
        expect(subtitles[2].texts!.length, 2);
        expect(subtitles[2].texts![0], contains('Multi-line support in TTML'));
        expect(
          subtitles[2].texts![1],
          contains('with clean line breaks and styling.'),
        );
      },
    );

    testWidgets('SubtitlesPage renders TTML section header', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SubtitlesPage(),
        ),
      );
      await tester.pump();

      expect(find.text('1. SRT Subtitles Example'), findsOneWidget);
      expect(find.text('2. WebVTT Subtitles Advanced Example'), findsOneWidget);
      expect(find.text('3. TTML Subtitles Example'), findsOneWidget);
      expect(
        find.text(
          'Player with TTML (Timed Text Markup Language) subtitles '
          'demonstrating XML styling, colors, regions, and line breaks.',
        ),
        findsOneWidget,
      );
    });
  });
}
