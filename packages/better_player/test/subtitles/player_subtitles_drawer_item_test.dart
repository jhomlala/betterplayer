import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/player_subtitles_drawer_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(
        body: widget,
      ),
    );
  }

  testWidgets('Subtitles drawer item renders text', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        const PlayerSubtitlesDrawerItem(
          subtitleText: 'Test Subtitle',
          configuration: PlayerSubtitlesConfiguration(
            outlineEnabled: false,
          ),
          innerTextStyle: TextStyle(),
        ),
      ),
    );

    expect(find.text('Test Subtitle', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'Subtitles drawer item renders text when outline enabled',
    (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const PlayerSubtitlesDrawerItem(
            subtitleText: 'HTML Subtitle',
            configuration: PlayerSubtitlesConfiguration(),
            innerTextStyle: TextStyle(),
          ),
        ),
      );

      expect(find.text('HTML Subtitle', findRichText: true), findsNWidgets(2));
    },
  );
  group('textBackgroundHorizontalPadding', () {
    double backgroundOverhang(WidgetTester tester) {
      final background = tester.getSize(
        find.descendant(
          of: find.byType(PlayerSubtitlesDrawerItem),
          matching: find.byType(ColoredBox),
        ),
      );
      final text = tester.getSize(
        find.text('Padded Subtitle', findRichText: true),
      );

      return background.width - text.width;
    }

    testWidgets('pads the text inside the background box', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const PlayerSubtitlesDrawerItem(
            subtitleText: 'Padded Subtitle',
            configuration: PlayerSubtitlesConfiguration(
              outlineEnabled: false,
              textBackgroundHorizontalPadding: 8,
            ),
            innerTextStyle: TextStyle(),
          ),
        ),
      );

      expect(backgroundOverhang(tester), 16);
    });

    testWidgets('defaults to no padding', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const PlayerSubtitlesDrawerItem(
            subtitleText: 'Padded Subtitle',
            configuration: PlayerSubtitlesConfiguration(
              outlineEnabled: false,
            ),
            innerTextStyle: TextStyle(),
          ),
        ),
      );

      expect(backgroundOverhang(tester), 0);
    });
  });
}
