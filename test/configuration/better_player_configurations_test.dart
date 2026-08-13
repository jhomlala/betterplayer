import 'package:better_player/better_player.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('BetterPlayer Configuration tests', () {
    test('BetterPlayerBufferingConfiguration default values', () {
      const config = BetterPlayerBufferingConfiguration();
      expect(config.minBufferMs, 25000);
      expect(config.maxBufferMs, 6553600);
    });

    test('BetterPlayerCacheConfiguration default values', () {
      const config = BetterPlayerCacheConfiguration();
      expect(config.useCache, false);
      expect(config.maxCacheSize, 10 * 1024 * 1024);
    });

    test('BetterPlayerDrmConfiguration default values', () {
      const config = BetterPlayerDrmConfiguration();
      expect(config.drmType, null);
    });

    test('BetterPlayerNotificationConfiguration default values', () {
      const config = BetterPlayerNotificationConfiguration();
      expect(config.showNotification, null);
    });

    test('BetterPlayerControlsConfiguration factories', () {
      final white = BetterPlayerControlsConfiguration.white();
      expect(white.controlBarColor, Colors.white);

      final cupertino = BetterPlayerControlsConfiguration.cupertino();
      expect(cupertino.playIcon, CupertinoIcons.play_arrow_solid);

      final theme = BetterPlayerControlsConfiguration.theme(ThemeData.light());
      expect(theme.textColor, ThemeData.light().textTheme.bodySmall?.color);
    });

    test('BetterPlayerConfiguration copyWith', () {
      const config = BetterPlayerConfiguration(autoPlay: true);
      final copied = config.copyWith(autoPlay: false);
      expect(copied.autoPlay, false);
      expect(copied.looping, false);
    });
  });

  group('VideoPlayerValue tests', () {
    test('VideoPlayerValue initialization', () {
      final value = VideoPlayerValue(duration: const Duration(seconds: 10));
      expect(value.duration, const Duration(seconds: 10));
      expect(value.initialized, true);
      expect(value.hasError, false);
      expect(value.aspectRatio, 1.0);
    });

    test('VideoPlayerValue uninitialized', () {
      final value = VideoPlayerValue.uninitialized();
      expect(value.initialized, false);
      expect(value.duration, null);
    });

    test('VideoPlayerValue copyWith', () {
      final value = VideoPlayerValue(duration: const Duration(seconds: 10));
      final newValue = value.copyWith(isPlaying: true, volume: 0.5);
      expect(newValue.isPlaying, true);
      expect(newValue.volume, 0.5);
      expect(newValue.duration, const Duration(seconds: 10));
    });
  });
}
