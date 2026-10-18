import 'dart:ui';

import 'package:better_player/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  setUpAll(BetterPlayerTestUtils.setupMockPlatform);

  group('controlsVisibilityStream tests', () {
    testWidgets(
      'emits true and false on Material controls lifecycle',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.material,
                  controlsHideTime: Duration(milliseconds: 500),
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayer(
                controller: controller,
              ),
            ),
          ),
        );

        // Wait for player and _initTimer to initialize controls
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(events, contains(true));
        expect(controller.isControlsVisible, true);

        // Programmatically hide controls
        controller.setControlsVisibility(false);
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);

        // Tap on player to show controls again
        await tester.tap(find.byType(BetterPlayer));
        await tester.pump();
        // Wait for transition to complete
        await tester.pump(const Duration(milliseconds: 350));
        expect(events.last, true);
        expect(controller.isControlsVisible, true);

        // Advance past controlsHideTime (500ms) + transition (300ms) to auto-hide
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'emits true and false on Cupertino controls lifecycle',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.cupertino,
                  controlsHideTime: Duration(milliseconds: 500),
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayer(
                controller: controller,
              ),
            ),
          ),
        );

        // Wait for player and _initTimer to initialize controls
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(events, contains(true));
        expect(controller.isControlsVisible, true);

        // Programmatically hide controls
        controller.setControlsVisibility(false);
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);

        // Tap on player to show controls again
        await tester.tap(find.byType(BetterPlayer));
        await tester.pump();
        // Wait for transition to complete
        await tester.pump(const Duration(milliseconds: 350));
        expect(events.last, true);
        expect(controller.isControlsVisible, true);

        // Advance past controlsHideTime (500ms) + transition (300ms) to auto-hide
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'emits true and false on Web controls lifecycle',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.web,
                  controlsHideTime: Duration(milliseconds: 300),
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayer(
                controller: controller,
              ),
            ),
          ),
        );

        // Wait for initialize
        await tester.pumpAndSettle();
        expect(events, contains(true));
        expect(controller.isControlsVisible, true);

        // Wait for controlsHideTime to hide
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'emits when custom controls trigger onControlsVisibilityChanged',
      (tester) async {
        void Function(bool)? visibilityCallback;

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.custom,
                  customControlsBuilder: (ctrl, onVisibilityChanged) {
                    visibilityCallback = onVisibilityChanged;
                    return const SizedBox();
                  },
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayer(
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(visibilityCallback, isNotNull);

        visibilityCallback!(true);
        await tester.pump();
        expect(events, [true]);
        expect(controller.isControlsVisible, true);

        visibilityCallback!(false);
        await tester.pump();
        expect(events, [true, false]);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'mounting PlayerWebControls does not trigger setState or markNeedsBuild during build',
      (tester) async {
        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.web,
                ),
              ),
            );

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        var rebuildCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                controller.controlsVisibilityStream.listen((_) {
                  setState(() {
                    rebuildCount++;
                  });
                });
                return Scaffold(
                  body: BetterPlayer(
                    controller: controller,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(rebuildCount, greaterThan(0));
        expect(controller.isControlsVisible, true);
      },
    );

    testWidgets(
      'routePageBuilder custom overlay does not flicker or repeatedly toggle visibility stream',
      (tester) async {
        VisibilityDetectorController.instance.updateInterval = Duration.zero;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              SystemChannels.platform,
              (methodCall) async => null,
            );
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        try {
          final mockPlayerEngineController = MockPlayerEngineController();
          mockPlayerEngineController.setDuration(const Duration(seconds: 100));

          final events = <bool>[];

          final controller =
              BetterPlayerTestUtils.setupBetterPlayerMockController(
                controller: mockPlayerEngineController,
                configuration: PlayerConfiguration(
                  controlsConfiguration: const PlayerControlsConfiguration(
                    playerTheme: PlayerTheme.web,
                    controlsHideTime: Duration(milliseconds: 300),
                  ),
                  routePageBuilder:
                      (
                        context,
                        animation,
                        secondaryAnimation,
                        controllerProvider,
                      ) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Material(
                              child: Stack(
                                children: <Widget>[
                                  Positioned.fill(
                                    child: controllerProvider,
                                  ),
                                  _RoutePageBuilderTestTopBar(
                                    controller: controllerProvider.controller,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                ),
              );

          controller.controlsVisibilityStream.listen(events.add);

          await controller.setupDataSource(
            PlayerDataSource.network(
              BetterPlayerTestUtils.forBiggerBlazesUrl,
            ),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BetterPlayer(controller: controller),
              ),
            ),
          );

          await tester.pumpAndSettle();

          controller.enterFullScreen();
          await tester.pump();
          await tester.pump();
          await tester.pumpAndSettle();

          // Mouse moves over top bar area
          final gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await gesture.addPointer(location: const Offset(100, 20));
          await tester.pump();

          final countBeforeMoves = events.length;

          // Move pointer across the top bar over several frames
          for (var i = 1; i <= 5; i++) {
            await gesture.moveTo(Offset(100, 20.0 + i));
            await tester.pump();
          }

          // In the buggy implementation, every movement over the top bar triggered
          // an exit and immediate re-entry loop emitting false, true, false, true...
          // With the fix, controls remain stable and do not oscillate.
          final newEvents = events.sublist(countBeforeMoves);
          expect(newEvents.where((e) => !e), isEmpty);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'calling setControlsVisibility(true) resets hide timer when controls are already visible',
      (tester) async {
        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.web,
                  controlsHideTime: Duration(milliseconds: 600),
                ),
              ),
            );

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayer(controller: controller),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(controller.isControlsVisible, isTrue);

        // Advance 300ms (less than controlsHideTime 600ms)
        await tester.pump(const Duration(milliseconds: 300));
        expect(controller.isControlsVisible, isTrue);

        // Reset hide timer by calling setControlsVisibility(true)
        controller.setControlsVisibility(true);
        await tester.pump();

        // Advance another 400ms (700ms from start, but only 400ms from reset)
        await tester.pump(const Duration(milliseconds: 400));
        expect(controller.isControlsVisible, isTrue);

        // Advance past reset timer expiry (another 300ms -> 700ms from reset)
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(controller.isControlsVisible, isFalse);
      },
    );

    testWidgets(
      'calling setControlsEnabled(false) hides controls and setControlsEnabled(true) restores them',
      (tester) async {
        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.material,
                  controlsHideTime: Duration(milliseconds: 600),
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayer(controller: controller),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(controller.isControlsVisible, isTrue);

        // Disable controls
        controller.setControlsEnabled(false);
        await tester.pumpAndSettle();
        expect(controller.controlsEnabled, isFalse);
        expect(controller.isControlsVisible, isFalse);
        expect(events.last, isFalse);

        // setControlsVisibility(true) should be ignored when controls are disabled
        controller.setControlsVisibility(true);
        await tester.pumpAndSettle();
        expect(controller.isControlsVisible, isFalse);
        expect(events.last, isFalse);

        // Re-enable controls
        controller.setControlsEnabled(true);
        await tester.pumpAndSettle();
        expect(controller.controlsEnabled, isTrue);
        expect(controller.isControlsVisible, isTrue);
        expect(events.last, isTrue);
      },
    );
  });
}

class _RoutePageBuilderTestTopBar extends StatelessWidget {
  const _RoutePageBuilderTestTopBar({required this.controller});

  final BetterPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: controller.controlsVisibilityStream,
      initialData: true,
      builder: (context, snapshot) {
        final isVisible = snapshot.data ?? true;
        return IgnorePointer(
          ignoring: !isVisible,
          child: ColoredBox(
            color: Colors.red,
            child: Offstage(
              offstage: !isVisible,
              child: const SizedBox(
                height: 50,
                width: double.infinity,
                child: Text('Video Title'),
              ),
            ),
          ),
        );
      },
    );
  }
}
