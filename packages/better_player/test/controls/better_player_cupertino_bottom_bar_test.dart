import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_cupertino_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  late BetterPlayerMockController mockController;
  late MockPlayerEngineController mockPlayerEngineController;

  setUp(() async {
    final mockMethodChannel = MockMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        );

    mockPlayerEngineController = MockPlayerEngineController();
    mockController = BetterPlayerMockController(
      const PlayerConfiguration(),
      playerEngineController: mockPlayerEngineController,
    );
    await mockController.setupDataSource(
      PlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
        liveStream: true,
      ),
    );
  });

  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(
        body: BetterPlayerControllerProvider(
          controller: mockController,
          child: widget,
        ),
      ),
    );
  }

  testWidgets('Cupertino bottom bar shows play button when paused', (
    tester,
  ) async {
    final controlsConfiguration = PlayerControlsConfiguration.cupertino();
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerCupertinoBottomBar(
          controlsConfiguration: controlsConfiguration,
          onPlayPause: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          barHeight: 40,

          iconColor: Colors.white,
          latestValue: VideoPlayerValue(duration: const Duration(seconds: 10)),
        ),
      ),
    );

    expect(find.byIcon(controlsConfiguration.playIcon), findsOneWidget);
  });

  testWidgets('Cupertino bottom bar shows pause button when playing', (
    tester,
  ) async {
    final controlsConfiguration = PlayerControlsConfiguration.cupertino();
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerCupertinoBottomBar(
          controlsConfiguration: controlsConfiguration,
          onPlayPause: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          barHeight: 40,

          iconColor: Colors.white,
          latestValue: VideoPlayerValue(
            duration: const Duration(seconds: 10),
            isPlaying: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(controlsConfiguration.pauseIcon), findsOneWidget);
  });

  testWidgets('Cupertino bottom bar triggers onPlayPause callback', (
    tester,
  ) async {
    var playPauseTriggered = false;
    final controlsConfiguration = PlayerControlsConfiguration.cupertino();
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerCupertinoBottomBar(
          controlsConfiguration: controlsConfiguration,
          onPlayPause: () {
            playPauseTriggered = true;
          },
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          barHeight: 40,

          iconColor: Colors.white,
          latestValue: VideoPlayerValue(duration: const Duration(seconds: 10)),
        ),
      ),
    );

    await tester.tap(find.byIcon(controlsConfiguration.playIcon));
    expect(playPauseTriggered, isTrue);
  });

  testWidgets(
    'Cupertino bottom bar icons have fixed sizes regardless of barHeight',
    (tester) async {
      final controlsConfiguration = PlayerControlsConfiguration.cupertino();
      await tester.pumpWidget(
        wrapWidget(
          BetterPlayerCupertinoBottomBar(
            controlsConfiguration: controlsConfiguration,
            onPlayPause: () {},
            onProgressBarDragStart: () {},
            onProgressBarDragEnd: () {},
            onProgressBarTapDown: () {},
            barHeight:
                100, // Very large barHeight to ensure size does not scale

            iconColor: Colors.white,
            latestValue: VideoPlayerValue(
              duration: const Duration(seconds: 10),
            ),
          ),
        ),
      );

      final playIcon = tester.widget<Icon>(
        find.byIcon(controlsConfiguration.playIcon),
      );
      expect(
        playIcon.size,
        24.0,
      ); // I changed the live stream icon size to 24 in my implementation
    },
  );
}
