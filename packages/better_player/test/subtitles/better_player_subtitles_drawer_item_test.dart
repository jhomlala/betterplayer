import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget wrapWidget(Widget widget) {
    return MaterialApp(
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
          outerTextStyle: TextStyle(),
        ),
      ),
    );

    expect(find.text('Test Subtitle', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'Subtitles drawer item renders HTML text twice when outline enabled',
    (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const PlayerSubtitlesDrawerItem(
            subtitleText: '<b>HTML</b> Subtitle',
            configuration: PlayerSubtitlesConfiguration(),
            innerTextStyle: TextStyle(),
            outerTextStyle: TextStyle(),
          ),
        ),
      );

      expect(find.text('HTML Subtitle', findRichText: true), findsNWidgets(2));
    },
  );
}
