import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_overflow_menu.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/mock_method_channel.dart';

void main() {
  late BetterPlayerMockController mockController;

  setUp(() {
    final mockMethodChannel = MockMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        );

    mockController = BetterPlayerMockController(
      const BetterPlayerConfiguration(),
    );
  });

  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      home: Scaffold(
        body: widget,
      ),
    );
  }

  testWidgets('Overflow menu shows all items when enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerOverflowMenu(
          controller: mockController,
          controlsConfiguration: const BetterPlayerControlsConfiguration(),
          onPlaybackSpeedClicked: () {},
          onSubtitlesClicked: () {},
          onQualitiesClicked: () {},
          onAudioTracksClicked: () {},
        ),
      ),
    );

    expect(
      find.text(mockController.translations.overflowMenuPlaybackSpeed),
      findsOneWidget,
    );
    expect(
      find.text(mockController.translations.overflowMenuSubtitles),
      findsOneWidget,
    );
    expect(
      find.text(mockController.translations.overflowMenuQuality),
      findsOneWidget,
    );
    expect(
      find.text(mockController.translations.overflowMenuAudioTracks),
      findsOneWidget,
    );
  });

  testWidgets('Overflow menu hides items when disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerOverflowMenu(
          controller: mockController,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enablePlaybackSpeed: false,
            enableSubtitles: false,
            enableQualities: false,
            enableAudioTracks: false,
          ),
          onPlaybackSpeedClicked: () {},
          onSubtitlesClicked: () {},
          onQualitiesClicked: () {},
          onAudioTracksClicked: () {},
        ),
      ),
    );

    expect(
      find.text(mockController.translations.overflowMenuPlaybackSpeed),
      findsNothing,
    );
    expect(
      find.text(mockController.translations.overflowMenuSubtitles),
      findsNothing,
    );
    expect(
      find.text(mockController.translations.overflowMenuQuality),
      findsNothing,
    );
    expect(
      find.text(mockController.translations.overflowMenuAudioTracks),
      findsNothing,
    );
  });

  testWidgets('Overflow menu triggers callbacks', (WidgetTester tester) async {
    var speedTriggered = false;
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerOverflowMenu(
          controller: mockController,
          controlsConfiguration: const BetterPlayerControlsConfiguration(),
          onPlaybackSpeedClicked: () {
            speedTriggered = true;
          },
          onSubtitlesClicked: () {},
          onQualitiesClicked: () {},
          onAudioTracksClicked: () {},
        ),
      ),
    );

    await tester.tap(
      find.text(mockController.translations.overflowMenuPlaybackSpeed),
    );
    expect(speedTriggered, isTrue);
  });

  testWidgets('Overflow menu shows custom items', (WidgetTester tester) async {
    var customTriggered = false;
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerOverflowMenu(
          controller: mockController,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            overflowMenuCustomItems: [
              BetterPlayerOverflowMenuItem(
                Icons.star,
                'Custom Item',
                () {
                  customTriggered = true;
                },
              ),
            ],
          ),
          onPlaybackSpeedClicked: () {},
          onSubtitlesClicked: () {},
          onQualitiesClicked: () {},
          onAudioTracksClicked: () {},
        ),
      ),
    );

    expect(find.text('Custom Item'), findsOneWidget);
    await tester.tap(find.text('Custom Item'));
    expect(customTriggered, isTrue);
  });
}
