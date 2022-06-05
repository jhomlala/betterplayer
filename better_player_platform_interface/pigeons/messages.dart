// @dart = 2.9

import 'package:pigeon/pigeon_lib.dart';

class TextureMessage {
  int textureId;
}

class LoopingMessage {
  int textureId;
  bool isLooping;
}

class VolumeMessage {
  int textureId;
  double volume;
}

class PlaybackSpeedMessage {
  int textureId;
  double speed;
}

class PositionMessage {
  int textureId;
  int position;
}

class CreateMessage {
  int minBufferMs;
  int maxBufferMs;
  int bufferForPlaybackMs;
  int bufferForPlaybackAfterRebufferMs;
}

class DataSourceMessage{
  int textureId;
  String key;
  String asset;
  String package;
  String uri;
  String formatHint;
  Map headers;
  bool useCache;
  int maxCacheSize;
  int maxCacheFileSize;
  String cacheKey;
  bool showNotification;
  String title;
  String author;
  String imageUrl;
  String notificationChannelName;
  int overriddenDuration;
  String licenseUrl;
  String certificateUrl;
  Map<String,String> drmHeaders;
  String activityName;
  String clearKey;
  String videoExtension;

}

class MixWithOthersMessage {
  bool mixWithOthers;
}

@HostApi(dartHostTestHandler: 'TestHostVideoPlayerApi')
abstract class BetterPlayerApi {
  void initialize();
  TextureMessage create(CreateMessage msg);
  void dispose(TextureMessage msg);
  void setDataSource(DataSourceMessage msg);
  void setLooping(LoopingMessage msg);
  void setVolume(VolumeMessage msg);
  void setPlaybackSpeed(PlaybackSpeedMessage msg);
  void play(TextureMessage msg);
  PositionMessage position(TextureMessage msg);
  void seekTo(PositionMessage msg);
  void pause(TextureMessage msg);
  void setMixWithOthers(MixWithOthersMessage msg);
}

void configurePigeon(PigeonOptions opts) {
  opts.dartOut = 'lib/messages.dart';
  opts.dartTestOut = 'test/test.dart';
}