import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerConfiguration tests', () {
    test('Default values', () {
      const config = BetterPlayerConfiguration();
      expect(config.autoPlay, false);
      expect(config.looping, false);
      expect(config.fullScreenByDefault, false);
      expect(config.placeholderOnTop, true);
      expect(config.handleLifecycle, true);
      expect(config.autoDispose, true);
      expect(config.expandToFill, true);
      expect(config.useRootNavigator, false);
    });

    test('copyWith', () {
      const config = BetterPlayerConfiguration();
      final newConfig = config.copyWith(
        autoPlay: true,
        looping: true,
        aspectRatio: 1,
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
      );
      expect(newConfig.autoPlay, true);
      expect(newConfig.looping, true);
      expect(newConfig.aspectRatio, 1);
      expect(
        newConfig.deviceOrientationsOnFullScreen,
        const [DeviceOrientation.portraitUp],
      );
      expect(newConfig.placeholderOnTop, true); // Should remain default
    });
  });

  group('BetterPlayerBufferingConfiguration tests', () {
    test('Default values', () {
      const config = BetterPlayerBufferingConfiguration();
      expect(config.minBufferMs, 25000);
      expect(config.maxBufferMs, 6553600);
      expect(config.bufferForPlaybackMs, 3000);
      expect(config.bufferForPlaybackAfterRebufferMs, 6000);
    });
  });

  group('BetterPlayerCacheConfiguration tests', () {
    test('Default values', () {
      const config = BetterPlayerCacheConfiguration();
      expect(config.useCache, false);
      expect(config.maxCacheSize, 10 * 1024 * 1024);
      expect(config.maxCacheFileSize, 10 * 1024 * 1024);
    });
  });

  group('BetterPlayerNotificationConfiguration tests', () {
    test('Default values', () {
      const config = BetterPlayerNotificationConfiguration();
      expect(config.showNotification, null);
    });
  });
}
