import 'package:better_player/src/engine/player_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_player_engine_controller.dart';

void main() {
  group('VideoProgressIndicator tests', () {
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
            body: VideoProgressIndicator(controller),
          ),
        ),
      );

      expect(find.byType(VideoProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly when allowScrubbing is false', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoProgressIndicator(
              controller,
              allowScrubbing: false,
            ),
          ),
        ),
      );

      expect(find.byType(VideoProgressIndicator), findsOneWidget);
    });

    testWidgets('renders scrubber when allowScrubbing is true', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
            ),
          ),
        ),
      );

      expect(find.byType(VideoProgressIndicator), findsOneWidget);
    });
  });
}
