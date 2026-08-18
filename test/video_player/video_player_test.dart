import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlayerController tests', () {
    const channel = MethodChannel('better_player_channel');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'create') {
              return {'textureId': 1};
            }
            if (methodCall.method == 'init') {
              return null;
            }
            if (methodCall.method == 'setDataSource') {
              return null;
            }
            if (methodCall.method == 'dispose') {
              return null;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
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
      final setDataSourceFuture = controller.setNetworkDataSource(
        'https://example.com/video.mp4',
      );

      final eventChannelName = 'better_player_channel/videoEvents$textureId';

      // Send initialized event first
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            eventChannelName,
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'initialized',
              'duration': 1000,
              'width': 1280.0,
              'height': 720.0,
              'key': 'https://example.com/video.mp4',
            }),
            (ByteData? data) {},
          );

      await setDataSourceFuture;

      expect(controller.value.size, const Size(1280, 720));

      // Send changedSize event
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            eventChannelName,
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'changedSize',
              'width': 1920.0,
              'height': 1080.0,
              'key': 'https://example.com/video.mp4',
            }),
            (ByteData? data) {},
          );

      expect(controller.value.size, const Size(1920, 1080));

      // Send changedSize event with invalid values - should NOT update size (stay at 1920x1080)
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            eventChannelName,
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'changedSize',
              'width': 0.0,
              'height': 0.0,
              'key': 'https://example.com/video.mp4',
            }),
            (ByteData? data) {},
          );

      expect(controller.value.size, const Size(1920, 1080));

      await controller.dispose();
    });
  });
}
