import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('BetterPlayerMultipleGestureDetector tests', () {
    testWidgets('Inherited data is accessible', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        BetterPlayerMultipleGestureDetector(
          onTap: () => tapped = true,
          child: Builder(
            builder: (context) {
              final detector = BetterPlayerMultipleGestureDetector.of(context);
              detector?.onTap?.call();
              return const SizedBox();
            },
          ),
        ),
      );
      expect(tapped, true);
    });

    test('updateShouldNotify returns false', () {
      const detector = BetterPlayerMultipleGestureDetector(
        child: SizedBox(),
      );
      expect(detector.updateShouldNotify(detector), false);
    });
  });
}
