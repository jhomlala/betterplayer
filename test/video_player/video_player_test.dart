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
            return null;
          });
    });

    test('VideoPlayerController updates size on changedSize event', () async {
      final controller = VideoPlayerController();
      // Wait for creation
      await Future<void>.delayed(Duration.zero);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'setDataSource') {
              return null;
            }
            return null;
          });

      // Call setDataSource to initialize the completer
      final setDataSourceFuture = controller.setNetworkDataSource(
        'https://example.com/video.mp4',
      );

      const textureId = 1;
      const eventChannelName = 'better_player_channel/videoEvents$textureId';

      // Send initialized event first
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            eventChannelName,
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'initialized',
              'duration': 1000,
              'width': 1280.0,
              'height': 720.0,
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
            }),
            (ByteData? data) {},
          );

      expect(controller.value.size, const Size(1920, 1080));

      await controller.dispose();
    });
  });
}
