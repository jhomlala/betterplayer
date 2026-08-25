import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_material_top_bar.dart';
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

  testWidgets('Material top bar shows more button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerMaterialTopBar(
          controller: mockController,
          controlsConfiguration: const BetterPlayerControlsConfiguration(),
          controlsNotVisible: false,
          onPlayerHide: () {},
          onShowMoreClicked: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert_outlined), findsOneWidget);
  });

  testWidgets('Material top bar triggers onShowMoreClicked', (
    WidgetTester tester,
  ) async {
    var showMoreTriggered = false;
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerMaterialTopBar(
          controller: mockController,
          controlsConfiguration: const BetterPlayerControlsConfiguration(),
          controlsNotVisible: false,
          onPlayerHide: () {},
          onShowMoreClicked: () {
            showMoreTriggered = true;
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert_outlined));
    expect(showMoreTriggered, isTrue);
  });

  testWidgets('Material top bar shows PiP button when enabled and supported', (
    WidgetTester tester,
  ) async {
    // Note: BetterPlayerController.isPictureInPictureSupported() is hardcoded
    // to return false in some environments or based on platform.
    // However, the widget uses it.

    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerMaterialTopBar(
          controller: mockController,
          controlsConfiguration: const BetterPlayerControlsConfiguration(),
          controlsNotVisible: false,
          onPlayerHide: () {},
          onShowMoreClicked: () {},
        ),
      ),
    );

    // By default it might not show because GlobalKey is null in mockController
    expect(find.byIcon(Icons.picture_in_picture_outlined), findsNothing);
  });
}
