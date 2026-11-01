import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_better_player_platform.dart';

class _DefaultCastExtension extends PlayerCastExtension {
  @override
  Future<void> showCastPicker() async {}
}

class _ActiveCastExtension extends PlayerCastExtension {
  _ActiveCastExtension({this.overlay});

  final Widget? overlay;
  final StreamController<bool> _castStreamController =
      StreamController<bool>.broadcast();
  int showCastPickerCallCount = 0;
  bool _active = true;

  @override
  bool get isCasting => _active;

  @override
  String? get targetDeviceName => 'Living Room TV';

  @override
  Stream<bool> get castingStream => _castStreamController.stream;

  @override
  Widget? get overlayWidget => overlay;

  @override
  Future<void> showCastPicker() async {
    showCastPickerCallCount++;
  }

  void setCasting(bool value) {
    _active = value;
    _castStreamController.add(value);
  }

  void dispose() {
    _castStreamController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBetterPlayerPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockBetterPlayerPlatform();
    BetterPlayerPlatform.instance = mockPlatform;
  });

  group('PlayerCastExtension', () {
    test('default implementation returns base safe values', () {
      final ext = _DefaultCastExtension();
      expect(ext.isCasting, isFalse);
      expect(ext.targetDeviceName, isNull);
      expect(ext.overlayWidget, isNull);
      expect(ext.castingStream, emitsDone);
    });

    test('overridden implementation provides casting metadata and overlay', () {
      const overlayWidget = Text('Casting to TV');
      final ext = _ActiveCastExtension(overlay: overlayWidget);

      expect(ext.isCasting, isTrue);
      expect(ext.targetDeviceName, 'Living Room TV');
      expect(ext.overlayWidget, overlayWidget);

      ext.dispose();
    });

    test(
      'controller reflects native AirPlay state and dispatches event',
      () async {
        final controller = BetterPlayerController(const PlayerConfiguration());
        expect(controller.isAirPlayActive, isFalse);
        expect(controller.isCasting, isFalse);
        expect(controller.isExternalPlaybackActive, isFalse);

        final events = <PlayerEvent>[];
        controller.addEventsListener(events.add);

        mockPlatform.externalPlaybackStreamController.add(true);
        await pumpEventQueue();

        expect(controller.isAirPlayActive, isTrue);
        expect(controller.isExternalPlaybackActive, isTrue);
        expect(
          events.any(
            (e) =>
                e.betterPlayerEventType ==
                PlayerEventType.externalPlaybackChanged,
          ),
          isTrue,
        );

        mockPlatform.externalPlaybackStreamController.add(false);
        await pumpEventQueue();

        expect(controller.isAirPlayActive, isFalse);
        expect(controller.isExternalPlaybackActive, isFalse);

        controller.dispose(forceDispose: true);
      },
    );

    test(
      'controller reflects PlayerCastExtension casting state and notifies listeners',
      () async {
        final castExt = _ActiveCastExtension();
        final controller = BetterPlayerController(
          PlayerConfiguration(extensions: [castExt]),
        );

        expect(controller.isCasting, isTrue);
        expect(controller.isAirPlayActive, isFalse);
        expect(controller.isExternalPlaybackActive, isTrue);

        final events = <PlayerEvent>[];
        controller.addEventsListener(events.add);

        var videoListenerCallCount = 0;
        controller.addVideoListener(() => videoListenerCallCount++);

        castExt.setCasting(false);
        await pumpEventQueue();

        expect(controller.isCasting, isFalse);
        expect(controller.isExternalPlaybackActive, isFalse);
        expect(videoListenerCallCount, greaterThan(0));
        expect(
          events.any(
            (e) =>
                e.betterPlayerEventType ==
                PlayerEventType.externalPlaybackChanged,
          ),
          isTrue,
        );

        controller.unregisterExtension(castExt);
        await pumpEventQueue();
        expect(controller.isCasting, isFalse);

        controller.dispose(forceDispose: true);
        castExt.dispose();
      },
    );

    test('showAirPlayPicker forwards textureId to platform', () async {
      final controller = BetterPlayerController(const PlayerConfiguration());
      await controller.showAirPlayPicker();

      expect(mockPlatform.showExternalPlaybackPickerCalls.length, 1);
      controller.dispose(forceDispose: true);
    });

    test(
      'showExternalPlaybackPicker delegates to CastExtension if present',
      () async {
        final castExt = _ActiveCastExtension();
        final controller = BetterPlayerController(
          PlayerConfiguration(extensions: [castExt]),
        );

        await controller.showExternalPlaybackPicker();

        expect(castExt.showCastPickerCallCount, 1);
        expect(mockPlatform.showExternalPlaybackPickerCalls, isEmpty);

        controller.dispose(forceDispose: true);
        castExt.dispose();
      },
    );

    test(
      'showExternalPlaybackPicker falls back to native AirPlay if no CastExtension',
      () async {
        final controller = BetterPlayerController(const PlayerConfiguration());

        await controller.showExternalPlaybackPicker();

        expect(mockPlatform.showExternalPlaybackPickerCalls.length, 1);
        controller.dispose(forceDispose: true);
      },
    );
  });
}
