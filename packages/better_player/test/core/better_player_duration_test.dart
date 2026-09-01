import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/better_player_mock_controller.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

  group('BetterPlayerController duration tests', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            mockMethodChannel.channel,
            mockMethodChannel.handle,
          );
    });

    test('isVideoInitialized returns false when duration is null', () {
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
      );
      final videoPlayerController = MockPlayerEngineController();
      controller.engineController = videoPlayerController;

      expect(controller.isVideoInitialized(), false);
    });

    test('isVideoInitialized returns true when duration is set', () {
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
      );
      final videoPlayerController = MockPlayerEngineController();
      controller.engineController = videoPlayerController;

      videoPlayerController.setDuration(const Duration(seconds: 10));
      expect(controller.isVideoInitialized(), true);
    });

    test(
      'getDuration returns correct duration from videoPlayerController',
      () async {
        final controller = BetterPlayerMockController(
          const PlayerConfiguration(),
        );
        final videoPlayerController = MockPlayerEngineController();
        controller.engineController = videoPlayerController;

        videoPlayerController.setDuration(const Duration(seconds: 15));
        expect(
          controller.videoPlayerController!.value.duration,
          const Duration(seconds: 15),
        );
      },
    );

    test(
      'initialization event updates duration and initialized state',
      () async {
        final controller = BetterPlayerMockController(
          const PlayerConfiguration(),
        );
        final videoPlayerController = MockPlayerEngineController();
        controller.engineController = videoPlayerController;

        expect(controller.isVideoInitialized(), false);

        videoPlayerController.emitInitialized();

        expect(controller.isVideoInitialized(), true);
        expect(
          controller.videoPlayerController!.value.duration,
          const Duration(seconds: 1),
        );
      },
    );
  });
}
