import 'package:better_player_android/better_player_android.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerAndroid tests', () {
    final androidPlayer = BetterPlayerAndroid();

    test('registerWith sets instance', () {
      BetterPlayerAndroid.registerWith();
      expect(VideoPlayerPlatform.instance, isA<BetterPlayerAndroid>());
    });

    test('buildView returns Texture widget', () {
      final widget = androidPlayer.buildView(1);
      expect(widget, isA<Texture>());
      expect((widget as Texture).textureId, 1);
    });

    test('dataSourceToMap includes formatHint', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        formatHint: VideoFormat.hls,
      );

      // We need a way to access the protected method or test it through public API.
      // Since it's protected, we can test it through a subclass or just by calling
      // a method that uses it.
      // However, for testing purposes, we can just call it if we are in the same library
      // or if we use a helper.
      // In Dart tests, we can often just call it if it's not truly private.
      // Let's see if we can just call it.

      final map = androidPlayer.dataSourceToMap(dataSource);
      expect(map['formatHint'], 'hls');
    });

    test(
      'dataSourceToMap for non-network source does not force formatHint',
      () {
        final dataSource = DataSource(
          sourceType: DataSourceType.asset,
          asset: 'assets/video.mp4',
        );

        final map = androidPlayer.dataSourceToMap(dataSource);
        expect(map.containsKey('formatHint'), false);
      },
    );
  });
}
