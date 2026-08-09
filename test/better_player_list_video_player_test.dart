import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'mock_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(
    () => {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        mockMethodChannel.channel,
        mockMethodChannel.handle,
      ),
    },
  );

  group('BetterPlayerListVideoPlayer tests', () {
    testWidgets('Initialization works', (WidgetTester tester) async {
      final dataSource =
          BetterPlayerDataSource.network('https://example.com/video.mp4');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerListVideoPlayer(dataSource),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BetterPlayerListVideoPlayer), findsOneWidget);
    });

    testWidgets('Controller works correctly', (WidgetTester tester) async {
      final dataSource =
          BetterPlayerDataSource.network('https://example.com/video.mp4');
      final listController = BetterPlayerListVideoPlayerController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerListVideoPlayer(
              dataSource,
              betterPlayerListVideoPlayerController: listController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test controller methods don't crash
      listController.play();
      listController.pause();
      listController.setVolume(0.5);
      listController.seekTo(const Duration(seconds: 1));
      listController.setMixWithOthers(true);

      expect(find.byType(BetterPlayerListVideoPlayer), findsOneWidget);
    });
  });
}
