import 'dart:io';
import 'package:better_player/src/engine/player_engine_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/material.dart';

class MockPlayerEngineController extends PlayerEngineController {
  MockPlayerEngineController() : super(autoCreate: false) {
    value = VideoPlayerValue(duration: null);
  }
  
  bool isLoopingState = false;
  double volume = 0;
  double speed = 1;
  Duration? lastSeekPosition;
  
  void emitInitialized() {
    value = value.copyWith(duration: const Duration(seconds: 1));
    notifyListeners();
  }
  
  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }
  
  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }
  
  @override
  Future<void> setLooping(bool looping) async {
    isLoopingState = looping;
  }
  
  void setBuffering(bool buffering) {
    value = value.copyWith(isBuffering: buffering);
  }
  
  void setDuration(Duration duration) {
    value = value.copyWith(duration: duration);
  }
  
  void setAspectRatio(double aspectRatio) {
    value = value.copyWith(size: Size(aspectRatio, 1));
  }
  
  @override
  Future<void> seekTo(Duration? position) async {
    lastSeekPosition = position;
    value = value.copyWith(position: position);
  }
  
  @override
  Future<void> setTrackParameters(int? width, int? height, int? bitrate) async {}
  
  @override
  Future<Duration?> get position async => value.position;
  
  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    value = value.copyWith(volume: volume);
  }
  
  @override
  Future<void> setSpeed(double speed) async {
    this.speed = speed;
    value = value.copyWith(speed: speed);
  }
  
  @override
  Future<void> setNetworkDataSource(
    String dataSource, {
    VideoFormat? formatHint,
    Map<String, String?>? headers,
    bool useCache = false,
    int? maxCacheSize,
    int? maxCacheFileSize,
    String? cacheKey,
    bool? showNotification,
    String? title,
    String? author,
    String? imageUrl,
    String? notificationChannelName,
    Duration? overriddenDuration,
    String? licenseUrl,
    String? certificateUrl,
    Map<String, String>? drmHeaders,
    String? activityName,
    String? clearKey,
    String? videoExtension,
  }) async {
    this.headers = headers;
    value = value.copyWith(duration: const Duration(seconds: 1));
  }
  
  @override
  Future<void> setFileDataSource(
    File file, {
    bool? showNotification,
    String? title,
    String? author,
    String? imageUrl,
    String? notificationChannelName,
    Duration? overriddenDuration,
    String? activityName,
    String? clearKey,
  }) async {
    value = value.copyWith(duration: const Duration(seconds: 1));
  }
  
  @override
  Future<void> setAssetDataSource(
    String dataSource, {
    String? package,
    bool? showNotification,
    String? title,
    String? author,
    String? imageUrl,
    String? notificationChannelName,
    Duration? overriddenDuration,
    String? activityName,
  }) async {
    value = value.copyWith(duration: const Duration(seconds: 1));
  }
  
  Map<String, String?>? headers;
}

