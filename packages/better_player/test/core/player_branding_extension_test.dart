import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';

class _DefaultBrandingExtension extends PlayerBrandingExtension {
  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}

class _HidingBrandingExtension extends PlayerBrandingExtension {
  @override
  bool get hideAboutMenu => true;

  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerBrandingExtension', () {
    test('default implementation returns hideAboutMenu false', () {
      final ext = _DefaultBrandingExtension();
      expect(ext.hideAboutMenu, isFalse);
    });

    test('overridden implementation returns hideAboutMenu true', () {
      final ext = _HidingBrandingExtension();
      expect(ext.hideAboutMenu, isTrue);
    });

    test('controller finds PlayerBrandingExtension via getExtension', () {
      final ext = _HidingBrandingExtension();
      final controller = BetterPlayerController(
        PlayerConfiguration(extensions: [ext]),
      );

      final retrieved = controller.getExtension<PlayerBrandingExtension>();
      expect(retrieved, isNotNull);
      expect(retrieved, ext);
      expect(retrieved!.hideAboutMenu, isTrue);
    });
  });
}
