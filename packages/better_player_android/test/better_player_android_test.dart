import 'package:better_player_android/better_player_android.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerAndroid tests', () {
    final androidPlayer = BetterPlayerAndroid();

    test('registerWith sets instance', () {
      BetterPlayerAndroid.registerWith();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerAndroid>());
    });

    test('buildView returns Texture widget', () {
      final widget = androidPlayer.buildView(1);
      expect(widget, isA<Texture>());
      expect((widget as Texture).textureId, 1);
    });

  });
}
