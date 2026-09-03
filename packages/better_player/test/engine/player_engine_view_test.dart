import 'package:better_player/src/engine/player_engine_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_player_engine_controller.dart';

void main() {
  group('PlayerEngineView tests', () {
    testWidgets('renders Container when controller is null', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerEngineView(null),
          ),
        ),
      );

      expect(find.byType(PlayerEngineView), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders when controller is provided', (widgetTester) async {
      final controller = MockPlayerEngineController();

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerEngineView(controller),
          ),
        ),
      );

      expect(find.byType(PlayerEngineView), findsOneWidget);
    });
  });
}
