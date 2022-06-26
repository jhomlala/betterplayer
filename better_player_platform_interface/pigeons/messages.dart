import 'package:pigeon/pigeon.dart';

class TextureMessage {
  int? textureId;
}

class VolumeMessage {
  int? textureId;
  double? volume;
}

class SetSpeedMessage {
  int? textureId;
  double? speed;
}

class CreateMessage {
  int? minBufferMs;
  int? maxBufferMs;
  int? bufferForPlaybackMs;
  int? bufferForPlaybackAfterRebufferMs;
}

class DataSourceMessage{
  int? textureId;
  String? key;
  String? asset;
  String? package;
  String? uri;
  String? formatHint;
  Map? headers;
  bool? useCache;
  int? maxCacheSize;
  int? maxCacheFileSize;
  String? cacheKey;
  bool? showNotification;
  String? title;
  String? author;
  String? imageUrl;
  String? notificationChannelName;
  int? overriddenDuration;
  String? licenseUrl;
  String? certificateUrl;
  Map<String?,String?>? drmHeaders;
  String? activityName;
  String? clearKey;
  String? videoExtension;
}

class SetLoopingMessage{
  int? textureId;
  bool? looping;
}

class SetTrackParametersMessage{
  int? textureId;
  int? width;
  int? height;
  int? bitrate;
}

class SeekToMessage {
  int? textureId;
  int? position;
}

class PositionMessage {
  int? textureId;
  int? position;
}

class EnablePictureInPictureMessage{
  int? textureId;
  double? top;
  double? left;
  double? width;
  double? height;
}

class SetAudioTrack{
  int? textureId;
  String? name;
  int? index;
}

class SetMixWithOthersMessage {
  int? textureId;
  bool? mixWithOthers;
}

class InnerPreCacheMessage{
  String? key;
  String? uri;
  String? certificateUrl;
  Map? headers;
  int? maxCacheSize;
  int? maxCacheFileSize;
  int? preCacheSize;
  String? cacheKey;
  String? videoExtension;
}

class PreCacheMessage{
  InnerPreCacheMessage? dataSource;
}

class StopPreCacheMessage{
  String? url;
  String? cacheKey;
}


@HostApi(dartHostTestHandler: 'TestHostVideoPlayerApi')
abstract class BetterPlayerApi {
  void initialize();
  TextureMessage create(CreateMessage msg);
  void dispose(TextureMessage msg);
  void setDataSource(DataSourceMessage msg);
  void setLooping(SetLoopingMessage msg);
  void setVolume(VolumeMessage msg);
  void setSpeed(SetSpeedMessage msg);
  void play(TextureMessage msg);
  void pause(TextureMessage msg);
  void setTrackParameters(SetTrackParametersMessage msg);
  void seekTo(SeekToMessage msg);
  PositionMessage position(TextureMessage msg);
  PositionMessage absolutePosition(TextureMessage msg);
  void enablePictureInPicture(EnablePictureInPictureMessage msg);
  bool isPictureInPictureEnabled(TextureMessage msg);
  void disablePictureInPicture(TextureMessage msg);
  void setAudioTrack(SetAudioTrack msg);
  void setMixWithOthers(SetMixWithOthersMessage msg);
  void clearCache();
  void preCache(PreCacheMessage msg);
  void stopPreCache(StopPreCacheMessage msg);

}

void configurePigeon(PigeonOptions opts) {
  //opts.dartOut = 'lib/messages.dart';
  //opts.dartTestOut = 'test/test.dart';
}