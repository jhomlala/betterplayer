import 'package:better_player_ios/better_player_ios.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerIOS tests', () {
    final iosPlayer = BetterPlayerIOS();

    test('registerWith sets instance', () {
      BetterPlayerIOS.registerWith();
      expect(VideoPlayerPlatform.instance, isA<BetterPlayerIOS>());
    });

    test('buildView returns UiKitView widget', () {
      final widget = iosPlayer.buildView(1);
      expect(widget, isA<UiKitView>());
      final uiKitView = widget as UiKitView;
      expect(uiKitView.viewType, 'pl.hasoft.better_player');
      expect(uiKitView.creationParams, {'textureId': 1});
    });

    test('dataSourceToMap throws Exception for DASH streams', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mpd',
      );

      expect(
        () => iosPlayer.dataSourceToMap(dataSource),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('DASH streams are not supported'),
          ),
        ),
      );
    });

    test('dataSourceToMap throws Exception for DASH format hint', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.m3u8',
        formatHint: VideoFormat.dash,
      );

      expect(
        () => iosPlayer.dataSourceToMap(dataSource),
        throwsA(isA<Exception>()),
      );
    });

    test('dataSourceToMap works for HLS streams', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.m3u8',
      );

      final map = iosPlayer.dataSourceToMap(dataSource);
      expect(map['uri'], 'https://example.com/video.m3u8');
    });
  });
}
