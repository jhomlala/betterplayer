import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';

class BetterPlayerAndroid extends MethodChannelVideoPlayer {
  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerAndroid();
  }

  @override
  Widget buildView(int? textureId) {
    return Texture(textureId: textureId!);
  }

  @override
  Map<String, dynamic> dataSourceToMap(DataSource dataSource) {
    final map = super.dataSourceToMap(dataSource);
    if (dataSource.sourceType == DataSourceType.network) {
      map['formatHint'] = dataSource.rawFormalHint;
    }
    return map;
  }
}
