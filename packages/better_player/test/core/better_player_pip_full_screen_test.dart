import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/player_full_screen_video.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

const _systemChromeCalls = {
  'SystemChrome.setPreferredOrientations',
  'SystemChrome.setEnabledSystemUIMode',
  'SystemChrome.setEnabledSystemUIOverlays',
};

const _wakelockChannels = [
  'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
  'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.isEnabled',
];

void main() {
  late List<String> systemChromeCalls;
  late int wakelockCalls;
  late MockPlayerEngineController engineController;
  late BetterPlayerMockController controller;

  setUpAll(() {
    BetterPlayerTestUtils.setupMockPlatform();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  Future<void> pumpPlayer(
    WidgetTester tester, {
    PlayerConfiguration configuration = const PlayerConfiguration(),
  }) async {
    systemChromeCalls = [];
    wakelockCalls = 0;
    const codec = StandardMessageCodec();
    for (final channel in _wakelockChannels) {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        channel,
        (message) async {
          wakelockCalls++;
          return codec.encodeMessage(<Object?>[false]);
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          channel,
          null,
        ),
      );
    }
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (_systemChromeCalls.contains(call.method)) {
          systemChromeCalls.add(call.method);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    engineController = MockPlayerEngineController()..isPipSupported = true;
    controller = BetterPlayerMockController(
      configuration,
      playerEngineController: engineController,
    );
    engineController.emitInitialized();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: BetterPlayer(controller: controller),
      ),
    );
  }

  Future<void> setPip(WidgetTester tester, {required bool isPip}) async {
    engineController.value = engineController.value.copyWith(isPip: isPip);
    engineController.notifyListeners();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Android PiP full screen makes no orientation or system UI changes',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpPlayer(tester);

        await controller.enablePictureInPicture(GlobalKey());
        await setPip(tester, isPip: true);

        expect(find.byType(PlayerFullScreenVideo), findsOneWidget);
        expect(systemChromeCalls, isEmpty);
        expect(wakelockCalls, 0);

        await setPip(tester, isPip: false);

        expect(find.byType(PlayerFullScreenVideo), findsNothing);
        expect(controller.isFullScreenForPip, isFalse);
        expect(systemChromeCalls, isEmpty);
        expect(wakelockCalls, 0);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Android PiP full screen keeps the screen on when screen sleep is not '
    'allowed',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpPlayer(
          tester,
          configuration: const PlayerConfiguration(allowedScreenSleep: false),
        );

        await controller.enablePictureInPicture(GlobalKey());
        await setPip(tester, isPip: true);

        expect(wakelockCalls, 1);

        await setPip(tester, isPip: false);

        expect(wakelockCalls, 2);
        expect(systemChromeCalls, isEmpty);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'user full screen still sets and restores orientation and system UI',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpPlayer(tester);

        controller.enterFullScreen();
        await tester.pumpAndSettle();

        expect(find.byType(PlayerFullScreenVideo), findsOneWidget);
        expect(
          systemChromeCalls,
          containsAll([
            'SystemChrome.setPreferredOrientations',
            'SystemChrome.setEnabledSystemUIMode',
          ]),
        );

        systemChromeCalls.clear();
        controller.exitFullScreen();
        await tester.pumpAndSettle();

        expect(find.byType(PlayerFullScreenVideo), findsNothing);
        expect(
          systemChromeCalls,
          containsAll([
            'SystemChrome.setPreferredOrientations',
            'SystemChrome.setEnabledSystemUIOverlays',
          ]),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'disposing the player during a PiP full screen restores nothing',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpPlayer(tester);

        await controller.enablePictureInPicture(GlobalKey());
        await setPip(tester, isPip: true);

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pumpAndSettle();

        expect(systemChromeCalls, isEmpty);
        expect(wakelockCalls, 0);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
