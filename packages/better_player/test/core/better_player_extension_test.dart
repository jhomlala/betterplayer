import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';

class _TestExtension extends BetterPlayerExtension {
  int attachCount = 0;
  int detachCount = 0;
  BetterPlayerController? attachedController;

  @override
  void onAttach(BetterPlayerController controller) {
    attachCount++;
    attachedController = controller;
  }

  @override
  void onDetach(BetterPlayerController controller) {
    detachCount++;
    if (attachedController == controller) {
      attachedController = null;
    }
  }
}

class _AnotherTestExtension extends BetterPlayerExtension {
  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('BetterPlayerExtension', () {
    test(
      'attaches extensions defined in PlayerConfiguration on controller creation',
      () {
        final extension = _TestExtension();
        final controller = BetterPlayerController(
          PlayerConfiguration(extensions: [extension]),
        );

        expect(extension.attachCount, 1);
        expect(extension.attachedController, controller);
        expect(controller.extensions, contains(extension));
      },
    );

    test('registerExtension attaches and unregisterExtension detaches', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      final extension = _TestExtension();

      controller.registerExtension(extension);
      expect(extension.attachCount, 1);
      expect(controller.extensions.length, 1);

      // Registering again does nothing
      controller.registerExtension(extension);
      expect(extension.attachCount, 1);

      controller.unregisterExtension(extension);
      expect(extension.detachCount, 1);
      expect(extension.attachedController, isNull);
      expect(controller.extensions, isEmpty);
    });

    test('getExtension returns matched extension by type', () {
      final ext1 = _TestExtension();
      final ext2 = _AnotherTestExtension();
      final controller = BetterPlayerController(
        PlayerConfiguration(extensions: [ext1, ext2]),
      );

      expect(controller.getExtension<_TestExtension>(), ext1);
      expect(controller.getExtension<_AnotherTestExtension>(), ext2);
    });

    test('controller dispose detaches all registered extensions', () {
      final ext1 = _TestExtension();
      final ext2 = _TestExtension();
      final controller = BetterPlayerController(
        PlayerConfiguration(extensions: [ext1]),
      );
      controller.registerExtension(ext2);

      expect(ext1.attachCount, 1);
      expect(ext2.attachCount, 1);

      controller.dispose(forceDispose: true);

      expect(ext1.detachCount, 1);
      expect(ext2.detachCount, 1);
      expect(controller.extensions, isEmpty);
    });
  });
}
