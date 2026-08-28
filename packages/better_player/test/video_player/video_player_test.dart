import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_better_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlayerController tests', () {
    late MockBetterPlayerPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;
    });

    test('VideoPlayerController updates size on changedSize event', () async {
      final controller = VideoPlayerController();

      // Wait for textureId to be available (completes _create)
      int? textureId;
      while (textureId == null) {
        textureId = controller.textureId;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(textureId, 1);

      // Call setDataSource to initialize the completer and wait for initialized event
      // The mock platform will automatically send the initialized event
      await controller.setNetworkDataSource(
        'https://example.com/video.mp4',
      );

      expect(controller.value.size, const Size(1280, 720));

      // Send changedSize event
      mockPlatform.sendEvent(
        textureId,
        VideoEvent(
          eventType: VideoEventType.changedSize,
          size: const Size(1920, 1080),
          key: 'https://example.com/video.mp4',
        ),
      );

      // Wait for event to be processed
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.value.size, const Size(1920, 1080));

      // Send changedSize event with invalid values - should NOT update size (stay at 1920x1080)
      mockPlatform.sendEvent(
        textureId,
        VideoEvent(
          eventType: VideoEventType.changedSize,
          size: const Size(0, 0),
          key: 'https://example.com/video.mp4',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.value.size, const Size(1920, 1080));

      await controller.dispose();
    });
  });
}
