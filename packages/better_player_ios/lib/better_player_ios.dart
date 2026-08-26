import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class BetterPlayerIOS extends MethodChannelVideoPlayer {
  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerIOS();
  }

  @override
  Widget buildView(int? textureId) {
    return UiKitView(
      viewType: 'pl.hasoft.better_player',
      creationParamsCodec: const StandardMessageCodec(),
      creationParams: {'textureId': textureId!},
    );
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    if (dataSource.uri?.contains('.mpd') == true ||
        dataSource.formatHint == VideoFormat.dash) {
      throw Exception(
        'DASH streams are not supported on iOS platform. Please use HLS instead.',
      );
    }
    return super.setDataSource(textureId, dataSource);
  }
}
