import 'package:better_player/src/engine/player_engine_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/mock_better_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerEngineController tests', () {
    late MockBetterPlayerPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;
    });

    test('PlayerEngineController updates size on changedSize event', () async {
      final controller = PlayerEngineController();

      int? textureId;
      while (textureId == null) {
        textureId = controller.textureId;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(textureId, 1);

      await controller.setNetworkDataSource(
        'https://example.com/video.mp4',
      );

      expect(controller.value.size, const Size(1280, 720));

      mockPlatform.sendEvent(
        textureId,
        const VideoEvent(
          eventType: VideoEventType.changedSize,
          size: Size(1920, 1080),
          key: 'https://example.com/video.mp4',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.value.size, const Size(1920, 1080));

      mockPlatform.sendEvent(
        textureId,
        const VideoEvent(
          eventType: VideoEventType.changedSize,
          size: Size.zero,
          key: 'https://example.com/video.mp4',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.value.size, const Size(1920, 1080));

      await controller.dispose();
    });

    test(
      'PlayerEngineController updates size and notifies listeners when changedSize arrives after initial zero size',
      () async {
        mockPlatform.initialVideoSize = Size.zero;
        final controller = PlayerEngineController();

        int? textureId;
        while (textureId == null) {
          textureId = controller.textureId;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        await controller.setNetworkDataSource('https://example.com/hls.m3u8');
        expect(controller.value.size, Size.zero);
        expect(controller.value.initialized, isTrue);

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        mockPlatform.sendEvent(
          textureId,
          const VideoEvent(
            eventType: VideoEventType.changedSize,
            size: Size(1920, 1080),
            key: 'https://example.com/hls.m3u8',
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(controller.value.size, const Size(1920, 1080));
        expect(notifyCount, greaterThan(0));

        for (final invalidSize in [
          const Size(0, 720),
          const Size(-100, -100),
        ]) {
          mockPlatform.sendEvent(
            textureId,
            VideoEvent(
              eventType: VideoEventType.changedSize,
              size: invalidSize,
              key: 'https://example.com/hls.m3u8',
            ),
          );
        }
        mockPlatform.sendEvent(
          textureId,
          const VideoEvent(
            eventType: VideoEventType.changedSize,
            key: 'https://example.com/hls.m3u8',
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(controller.value.size, const Size(1920, 1080));

        await controller.dispose();
      },
    );

    test(
      'PlayerEngineController continues polling position after seekTo while playing',
      () async {
        final controller = PlayerEngineController();

        int? textureId;
        while (textureId == null) {
          textureId = controller.textureId;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        await controller.setNetworkDataSource('https://example.com/video.mp4');
        await controller.play();

        mockPlatform.currentPosition = const Duration(seconds: 5);
        await controller.seekTo(const Duration(seconds: 5));
        expect(controller.value.position, const Duration(seconds: 5));

        mockPlatform.currentPosition = const Duration(seconds: 6);
        await Future<void>.delayed(const Duration(milliseconds: 350));
        expect(controller.value.position, const Duration(seconds: 6));

        await controller.dispose();
      },
    );

    test('play and pause toggle isPlaying and notify listeners', () async {
      final controller = PlayerEngineController();

      int? textureId;
      while (textureId == null) {
        textureId = controller.textureId;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await controller.setNetworkDataSource('https://example.com/video.mp4');

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.play();
      expect(controller.value.isPlaying, isTrue);
      expect(notifyCount, 1);

      await controller.pause();
      expect(controller.value.isPlaying, isFalse);
      expect(notifyCount, 2);

      await controller.dispose();
    });

    test(
      'setVolume and setSpeed update engine value and notify listeners',
      () async {
        final controller = PlayerEngineController();

        int? textureId;
        while (textureId == null) {
          textureId = controller.textureId;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        await controller.setNetworkDataSource('https://example.com/video.mp4');

        await controller.setVolume(0.8);
        expect(controller.value.volume, 0.8);

        await controller.setSpeed(1.5);
        expect(controller.value.speed, 1.5);

        await controller.dispose();
      },
    );

    test('bufferingUpdate event updates buffered ranges in value', () async {
      final controller = PlayerEngineController();

      int? textureId;
      while (textureId == null) {
        textureId = controller.textureId;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await controller.setNetworkDataSource('https://example.com/video.mp4');

      final testRanges = [
        const DurationRange(Duration.zero, Duration(seconds: 15)),
      ];

      mockPlatform.sendEvent(
        textureId,
        VideoEvent(
          eventType: VideoEventType.bufferingUpdate,
          buffered: testRanges,
          key: 'https://example.com/video.mp4',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.value.buffered, testRanges);

      await controller.dispose();
    });

    test(
      'completed event sets isPlaying to false and sets position to duration',
      () async {
        final controller = PlayerEngineController();

        int? textureId;
        while (textureId == null) {
          textureId = controller.textureId;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        await controller.setNetworkDataSource('https://example.com/video.mp4');
        await controller.play();
        expect(controller.value.isPlaying, isTrue);

        mockPlatform.sendEvent(
          textureId,
          const VideoEvent(
            eventType: VideoEventType.completed,
            key: 'https://example.com/video.mp4',
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(controller.value.isPlaying, isFalse);
        expect(controller.value.position, controller.value.duration);

        await controller.dispose();
      },
    );
  });
}
