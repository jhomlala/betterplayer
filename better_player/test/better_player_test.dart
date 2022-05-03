import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'better_player_mock_controller.dart';
import 'better_player_test_utils.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets("Better Player simple player - network",
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWidget(
        BetterPlayer.network(BetterPlayerTestUtils.bugBuckBunnyVideoUrl)));
    expect(find.byWidgetPredicate((widget) => widget is BetterPlayer),
        findsOneWidget);
  });

  testWidgets("Better Player simple player - file",
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWidget(
        BetterPlayer.network(BetterPlayerTestUtils.bugBuckBunnyVideoUrl)));
    expect(find.byWidgetPredicate((widget) => widget is BetterPlayer),
        findsOneWidget);
  });

  testWidgets("BetterPlayer - with controller", (WidgetTester tester) async {
    final BetterPlayerMockController betterPlayerController =
        BetterPlayerMockController(const BetterPlayerConfiguration());
    await tester.pumpWidget(_wrapWidget(BetterPlayer(
      controller: betterPlayerController,
    )));
    expect(find.byWidgetPredicate((widget) => widget is BetterPlayer),
        findsOneWidget);
  });
}

///Wrap widget with material app to handle all features like navigation and
///localization properly.
Widget _wrapWidget(Widget widget) {
  return MaterialApp(home: widget);
}
