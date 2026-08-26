import 'package:better_player_ios/better_player_ios.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerIOS tests', () {
    final iosPlayer = BetterPlayerIOS();

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
