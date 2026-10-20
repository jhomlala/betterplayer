import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_better_player_platform.dart';

class _DefaultSecurityExtension extends PlayerSecurityExtension {
  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}

class _AuthorizedSecurityExtension extends PlayerSecurityExtension {
  _AuthorizedSecurityExtension({this.overlay});

  final Widget? overlay;

  @override
  bool get isScreenCaptureProtectionAuthorized => true;

  @override
  Widget? get overlayWidget => overlay;

  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBetterPlayerPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockBetterPlayerPlatform();
    BetterPlayerPlatform.instance = mockPlatform;
  });

  group('PlayerSecurityExtension', () {
    test(
      'default implementation returns false for protection authorization',
      () {
        final ext = _DefaultSecurityExtension();
        expect(ext.isScreenCaptureProtectionAuthorized, isFalse);
        expect(ext.overlayWidget, isNull);
      },
    );

    test(
      'overridden implementation returns true and provides overlayWidget',
      () {
        const testWidget = Text('Watermark');
        final ext = _AuthorizedSecurityExtension(overlay: testWidget);
        expect(ext.isScreenCaptureProtectionAuthorized, isTrue);
        expect(ext.overlayWidget, testWidget);
      },
    );

    test(
      'controller blocks screen capture protection without authorized extension',
      () async {
        final controller = BetterPlayerController(
          const PlayerConfiguration(),
        );

        expect(controller.isScreenCaptureProtectionAuthorized, isFalse);
        await controller.setScreenCaptureProtection(enabled: true);

        expect(mockPlatform.setScreenCaptureProtectionCalls, isEmpty);
      },
    );

    test(
      'controller blocks screen capture protection with default unauthorized extension',
      () async {
        final ext = _DefaultSecurityExtension();
        final controller = BetterPlayerController(
          PlayerConfiguration(extensions: [ext]),
        );

        expect(controller.isScreenCaptureProtectionAuthorized, isFalse);
        await controller.setScreenCaptureProtection(enabled: true);

        expect(mockPlatform.setScreenCaptureProtectionCalls, isEmpty);
      },
    );

    test(
      'controller enables screen capture protection when extension is authorized',
      () async {
        final ext = _AuthorizedSecurityExtension();
        final controller = BetterPlayerController(
          PlayerConfiguration(extensions: [ext]),
        );

        expect(controller.isScreenCaptureProtectionAuthorized, isTrue);
        await controller.setScreenCaptureProtection(enabled: true);
        await controller.setScreenCaptureProtection(enabled: false);

        expect(mockPlatform.setScreenCaptureProtectionCalls, [true, false]);
      },
    );

    test(
      'controller forwards screenCaptureStream events from platform',
      () async {
        final controller = BetterPlayerController(
          const PlayerConfiguration(),
        );

        final events = <bool>[];
        final sub = controller.screenCaptureStream.listen(events.add);

        mockPlatform.screenCaptureStreamController.add(true);
        mockPlatform.screenCaptureStreamController.add(false);
        await pumpEventQueue();

        expect(events, [true, false]);
        await sub.cancel();
      },
    );
  });
}
