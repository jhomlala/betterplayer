import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

class BetterPlayerMockController extends BetterPlayerController {
  BetterPlayerMockController(
      BetterPlayerConfiguration betterPlayerConfiguration)
      : super(betterPlayerConfiguration);
}

const MethodChannel channel = MethodChannel("better_player_channel");
const MethodChannel eventChannel =
    MethodChannel("better_player_channel/videoEvents1");
const String bugBuckBunnyVideoUrl =
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
const String forBiggerBlazesUrl =
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";

void main() {
  //WidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets("Better Player simple player - network",
      (WidgetTester tester) async {
    await tester
        .pumpWidget(_wrapWidget(BetterPlayer.network(bugBuckBunnyVideoUrl)));
    expect(find.byWidgetPredicate((widget) => widget is BetterPlayer),
        findsOneWidget);
  });

  testWidgets("Better Player simple player - file",
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWidget(BetterPlayer.file("")));
    expect(find.byWidgetPredicate((widget) => widget is BetterPlayer),
        findsOneWidget);
  });

  testWidgets("BetterPlayer - with controller", (WidgetTester tester) async {
    BetterPlayerMockController betterPlayerController =
        BetterPlayerMockController(BetterPlayerConfiguration());
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
