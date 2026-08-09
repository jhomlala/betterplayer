import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final config = BetterPlayerDrmConfiguration();
      expect(config.drmType, null);
    });

    test('BetterPlayerNotificationConfiguration default values', () {
      const config = BetterPlayerNotificationConfiguration();
      expect(config.showNotification, null);
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
