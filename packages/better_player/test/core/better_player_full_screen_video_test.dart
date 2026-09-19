import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/better_player_full_screen_video.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';

void main() {
  testWidgets(
    'BetterPlayerFullScreenVideo contains AnnotatedRegion and correct background color',
    (tester) async {
      final mockController = BetterPlayerMockController(
        const PlayerConfiguration(),
      );
      final controllerProvider = BetterPlayerControllerProvider(
        controller: mockController,
        child: const SizedBox(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BetterPlayerFullScreenVideo(
            controllerProvider: controllerProvider,
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);

      expect(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        findsOneWidget,
      );

      final annotatedRegion = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          );
      expect(annotatedRegion.value, SystemUiOverlayStyle.light);
    },
  );
}
