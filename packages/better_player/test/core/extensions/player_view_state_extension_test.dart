import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerViewStateExtension', () {
    late BetterPlayerController controller;

    setUp(() {
      controller = BetterPlayerController(const PlayerConfiguration());
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      'enterFullScreen sets isFullScreen to true and ignores duplicate calls',
      () {
        expect(controller.isFullScreen, isFalse);

        controller.enterFullScreen();
        expect(controller.isFullScreen, isTrue);

        controller.enterFullScreen();
        expect(controller.isFullScreen, isTrue);
      },
    );

    test('exitFullScreen sets isFullScreen to false', () {
      controller.enterFullScreen();
      expect(controller.isFullScreen, isTrue);

      controller.exitFullScreen();
      expect(controller.isFullScreen, isFalse);
    });

    test('toggleFullScreen toggles fullscreen state', () {
      expect(controller.isFullScreen, isFalse);

      controller.toggleFullScreen();
      expect(controller.isFullScreen, isTrue);

      controller.toggleFullScreen();
      expect(controller.isFullScreen, isFalse);
    });

    test(
      'setControlsVisibility updates visibility when controls are enabled',
      () async {
        final visibilityEmissions = <bool>[];
        final subscription = controller.controlsVisibilityStream.listen(
          visibilityEmissions.add,
        );

        controller.setControlsVisibility(false);
        controller.setControlsVisibility(true);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(visibilityEmissions, [false, true]);

        await subscription.cancel();
      },
    );

    test(
      'setControlsVisibility is ignored when controls are disabled',
      () async {
        final visibilityEmissions = <bool>[];
        final subscription = controller.controlsVisibilityStream.listen(
          visibilityEmissions.add,
        );

        controller.setControlsEnabled(false);
        expect(controller.controlsEnabled, isFalse);

        controller.setControlsVisibility(true);
        expect(controller.isControlsVisible, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(visibilityEmissions, [false]);

        await subscription.cancel();
      },
    );

    test('toggleControlsVisibility updates state and posts events', () {
      final events = <PlayerEvent>[];
      controller.addEventsListener(events.add);

      controller.toggleControlsVisibility(true);
      expect(controller.isControlsVisible, isTrue);
      expect(
        events.any(
          (e) => e.betterPlayerEventType == PlayerEventType.controlsVisible,
        ),
        isTrue,
      );

      controller.toggleControlsVisibility(false);
      expect(controller.isControlsVisible, isFalse);
      expect(
        events.any(
          (e) => e.betterPlayerEventType == PlayerEventType.controlsHiddenEnd,
        ),
        isTrue,
      );
    });

    test('setControlsAlwaysVisible updates controls visibility and state', () {
      controller.setControlsAlwaysVisible(true);
      expect(controller.isControlsVisible, isTrue);

      controller.setControlsAlwaysVisible(false);
      expect(controller.isControlsVisible, isFalse);
    });

    test('overridden aspect ratio takes precedence in getAspectRatio', () {
      final configuredController = BetterPlayerController(
        const PlayerConfiguration(aspectRatio: 16 / 9),
      );

      expect(configuredController.getAspectRatio(), 16 / 9);

      configuredController.setOverriddenAspectRatio(4 / 3);
      expect(configuredController.getAspectRatio(), 4 / 3);

      configuredController.dispose();
    });

    test('overridden fit takes precedence in getFit', () {
      final configuredController = BetterPlayerController(
        const PlayerConfiguration(fit: BoxFit.contain),
      );

      expect(configuredController.getFit(), BoxFit.contain);

      configuredController.setOverriddenFit(BoxFit.cover);
      expect(configuredController.getFit(), BoxFit.cover);

      configuredController.dispose();
    });
  });
}
