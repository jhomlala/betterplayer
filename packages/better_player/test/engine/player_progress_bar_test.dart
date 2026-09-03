import 'package:better_player/src/engine/player_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_player_engine_controller.dart';

void main() {
  group('PlayerProgressIndicator tests', () {
    late MockPlayerEngineController controller;

    setUp(() {
      controller = MockPlayerEngineController();
    });

    testWidgets('renders correctly when allowScrubbing is null or omitted', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerProgressIndicator(controller),
          ),
        ),
      );

      expect(find.byType(PlayerProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly when allowScrubbing is false', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerProgressIndicator(
              controller,
              allowScrubbing: false,
            ),
          ),
        ),
      );

      expect(find.byType(PlayerProgressIndicator), findsOneWidget);
    });

    testWidgets('renders scrubber when allowScrubbing is true', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerProgressIndicator(
              controller,
              allowScrubbing: true,
            ),
          ),
        ),
      );

      expect(find.byType(PlayerProgressIndicator), findsOneWidget);
    });
  });
}
