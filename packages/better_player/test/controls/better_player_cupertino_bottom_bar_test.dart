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
      PlayerDataSource.network(BetterPlayerTestUtils.forBiggerBlazesUrl),
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
          controlsNotVisible: false,
          onPlayerHide: () {},
          onPlayPause: () {},
          onSkipBack: () {},
          onSkipForward: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          barHeight: 40,
          marginSize: 5,
          backgroundColor: Colors.black,
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
          controlsNotVisible: false,
          onPlayerHide: () {},
          onPlayPause: () {},
          onSkipBack: () {},
          onSkipForward: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          barHeight: 40,
          marginSize: 5,
          backgroundColor: Colors.black,
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
          controlsNotVisible: false,
          onPlayerHide: () {},
          onPlayPause: () {
            playPauseTriggered = true;
          },
          onSkipBack: () {},
          onSkipForward: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          barHeight: 40,
          marginSize: 5,
          backgroundColor: Colors.black,
          iconColor: Colors.white,
          latestValue: VideoPlayerValue(duration: const Duration(seconds: 10)),
        ),
      ),
    );

    await tester.tap(find.byIcon(controlsConfiguration.playIcon));
    expect(playPauseTriggered, isTrue);
  });
}
