import 'package:better_player_ios/better_player_ios.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerIOS tests', () {
    final iosPlayer = BetterPlayerIOS();

    test('registerWith sets instance', () {
      BetterPlayerIOS.registerWith();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerIOS>());
    });

    test('buildView returns UiKitView widget', () {
      final widget = iosPlayer.buildView(1);
      expect(widget, isA<UiKitView>());
      final uiKitView = widget as UiKitView;
      expect(uiKitView.viewType, 'better_player_view');
      expect(uiKitView.creationParams, {'textureId': 1});
    });

  });
}
