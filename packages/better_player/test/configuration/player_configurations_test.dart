import 'package:better_player/better_player.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('BetterPlayer Configuration tests', () {
    test('BufferingConfiguration default values', () {
      const config = BufferingConfiguration();
      expect(config.minBufferMs, 25000);
      expect(config.maxBufferMs, 6553600);
    });

    test('CacheConfiguration default values', () {
      const config = CacheConfiguration();
      expect(config.useCache, false);
      expect(config.maxCacheSize, 10 * 1024 * 1024);
    });

    test('DrmConfiguration default values', () {
      const config = DrmConfiguration();
      expect(config.drmType, null);
    });

    test('NotificationConfiguration default values', () {
      const config = NotificationConfiguration();
      expect(config.showNotification, null);
    });

    test('PlayerControlsConfiguration default values', () {
      const config = PlayerControlsConfiguration();
      expect(config.controlsHideTime, const Duration(seconds: 3));
      expect(config.controlsTransitionTime, const Duration(milliseconds: 300));
      expect(config.aboutIcon, Icons.info_outline);
    });

    test('PlayerControlsConfiguration factories', () {
      final white = PlayerControlsConfiguration.white();
      expect(white.controlBarColor, Colors.white);

      final cupertino = PlayerControlsConfiguration.cupertino();
      expect(cupertino.playIcon, CupertinoIcons.play_arrow_solid);
      expect(cupertino.aboutIcon, CupertinoIcons.info_circle);

      final withCupertino = const PlayerControlsConfiguration()
          .withCupertinoIcons();
      expect(withCupertino.aboutIcon, CupertinoIcons.info_circle);

      const customIcon = Icons.help_outline;
      final withCustom = const PlayerControlsConfiguration(
        aboutIcon: customIcon,
      ).withCupertinoIcons();
      expect(withCustom.aboutIcon, customIcon);

      final theme = PlayerControlsConfiguration.theme(ThemeData.light());
      expect(theme.textColor, ThemeData.light().textTheme.bodySmall?.color);
    });

    test('PlayerConfiguration copyWith', () {
      const config = PlayerConfiguration(
        autoPlay: true,
        autoDetectFullscreenAspectRatio: true,
      );
      final copied = config.copyWith(autoPlay: false);
      expect(copied.autoPlay, false);
      expect(copied.looping, false);
      expect(copied.autoDetectFullscreenAspectRatio, true);
    });

    test(
      'PlayerDataSource copyWith preserves notificationConfiguration, bufferingConfiguration, and asmsTrackNames',
      () {
        const originalNotification = NotificationConfiguration(
          showNotification: true,
          title: 'Custom Title',
          author: 'Custom Author',
        );
        const originalBuffering = BufferingConfiguration(
          minBufferMs: 50000,
          maxBufferMs: 100000,
        );
        final original = PlayerDataSource(
          DataSourceType.network,
          'https://example.com/video.mp4',
          notificationConfiguration: originalNotification,
          bufferingConfiguration: originalBuffering,
          asmsTrackNames: const <String>['720p', '1080p'],
        );

        final copied = original.copyWith(
          url: 'https://example.com/video_720p.mp4',
        );

        expect(copied.notificationConfiguration?.showNotification, isTrue);
        expect(copied.notificationConfiguration?.title, 'Custom Title');
        expect(copied.bufferingConfiguration.minBufferMs, 50000);
        expect(copied.bufferingConfiguration.maxBufferMs, 100000);
        expect(copied.asmsTrackNames, const <String>['720p', '1080p']);
      },
    );
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
