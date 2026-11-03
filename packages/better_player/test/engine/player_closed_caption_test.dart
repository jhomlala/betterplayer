import 'package:better_player/src/engine/player_closed_caption.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerClosedCaption', () {
    testWidgets('renders SizedBox.shrink when text is null', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: PlayerClosedCaption(),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders Text when text is provided', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: PlayerClosedCaption(text: 'Caption text'),
        ),
      );

      expect(find.text('Caption text'), findsOneWidget);
    });

    testWidgets('applies custom textStyle when provided', (tester) async {
      const customStyle = TextStyle(fontSize: 20, color: Colors.yellow);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: PlayerClosedCaption(
            text: 'Styled caption',
            textStyle: customStyle,
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Styled caption'));
      expect(textWidget.style?.fontSize, 20);
      expect(textWidget.style?.color, Colors.yellow);
    });
  });
}
