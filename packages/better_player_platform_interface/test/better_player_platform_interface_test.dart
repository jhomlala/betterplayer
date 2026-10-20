import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestBetterPlayerPlatform extends BetterPlayerPlatform {}

void main() {
  group('BetterPlayerPlatform screen capture defaults', () {
    test('setScreenCaptureProtection completes without error', () async {
      final platform = _TestBetterPlayerPlatform();
      await expectLater(
        platform.setScreenCaptureProtection(enabled: true),
        completes,
      );
      await expectLater(
        platform.setScreenCaptureProtection(enabled: false),
        completes,
      );
    });

    test('screenCaptureStream emits nothing by default', () async {
      final platform = _TestBetterPlayerPlatform();
      final events = <bool>[];
      final subscription = platform.screenCaptureStream.listen(events.add);
      await pumpEventQueue();
      expect(events, isEmpty);
      await subscription.cancel();
    });
  });
}
