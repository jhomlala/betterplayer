part of '../better_player_controller.dart';

extension PlayerDataSourceExtension on BetterPlayerController {
  ///Setup new data source in Better Player.
  Future setupDataSource(PlayerDataSource betterPlayerDataSource) async {
    PlayerLogger.info(
      message: 'setupDataSource starting',
      textureId: textureId,
    );
    postEvent(
      PlayerEvent(
        PlayerEventType.setupDataSource,
        parameters: <String, dynamic>{
          PlayerEventConstants.dataSourceParameter: betterPlayerDataSource,
        },
      ),
    );

    _postControllerEvent(PlayerControllerEvent.setupDataSource);
    _playbackState = _playbackState.copyWith(
      hasCurrentDataSourceStarted: false,
    );
    _playbackState = _playbackState.copyWith(
      hasCurrentDataSourceInitialized: false,
    );
    _betterPlayerDataSource = betterPlayerDataSource;
    _subtitleState = _subtitleState.copyWith(subtitlesSourceList: []);

    final createdNewController = _engine == null;

    ///Build _engine if null
    if (createdNewController) {
      _engine = PlayerEngineController(
        bufferingConfiguration: betterPlayerDataSource.bufferingConfiguration,
      );
      _engine?.addListener(_onVideoPlayerChanged);
    }

    ///Clear asms tracks
    _trackState = _trackState.copyWith(asmsTracks: []);
    _trackState = _trackState.copyWith(asmsAudioTracks: []);
    _trackState = _trackState.copyWith(clearAsmsAudioTrack: true);

    ///Setup subtitles
    final betterPlayerSubtitlesSourceList = betterPlayerDataSource.subtitles;
    if (betterPlayerSubtitlesSourceList != null) {
      _subtitleState = _subtitleState.copyWith(subtitlesSourceList: [
        ..._subtitleState.subtitlesSourceList,
        ...betterPlayerDataSource.subtitles!,
      ]);
    }

    final setupFutures = <Future<dynamic>>[
      _setupDataSource(betterPlayerDataSource),
    ];
    if (_isDataSourceAsms(betterPlayerDataSource)) {
      setupFutures.add(_setupAsmsDataSource(betterPlayerDataSource));
    }
    try {
      await Future.wait(setupFutures);
      PlayerLogger.info(
        message: 'Data source setup complete: ${betterPlayerDataSource.url}',
        textureId: textureId,
      );
    } catch (exception) {
      PlayerLogger.error(
        message: 'Data source setup failed: $exception',
        textureId: textureId,
        error: exception,
      );
      if (createdNewController) {
        _engine?.dispose();
        _engine = null;
      }
      _postEvent(
        PlayerEvent(
          PlayerEventType.exception,
          parameters: <String, dynamic>{
            'exception': exception.toString().replaceFirst('Exception: ', ''),
          },
        ),
      );
      return;
    }

    _setupSubtitles();
    setTrack(PlayerAsmsTrack.defaultTrack());
  }

  ///Check if given [betterPlayerDataSource] is HLS / DASH-type data source.
  bool _isDataSourceAsms(PlayerDataSource betterPlayerDataSource) =>
      (BetterPlayerAsmsUtils.isDataSourceHls(betterPlayerDataSource.url) ||
          betterPlayerDataSource.videoFormat == VideoFormat.hls) ||
      (BetterPlayerAsmsUtils.isDataSourceDash(betterPlayerDataSource.url) ||
          betterPlayerDataSource.videoFormat == VideoFormat.dash);

  ///Configure HLS / DASH data source based on provided data source and configuration.
  ///This method configures tracks, subtitles and audio tracks from given
  ///master playlist.
  Future<void> _setupAsmsDataSource(PlayerDataSource source) async {
    final data = await BetterPlayerAsmsUtils.getDataFromUrl(
      betterPlayerDataSource!.url,
      _getHeaders(),
    );
    if (data != null) {
      final response = await BetterPlayerAsmsUtils.parse(
        data,
        betterPlayerDataSource!.url,
      );

      /// Load tracks
      if (_betterPlayerDataSource?.useAsmsTracks == true) {
        _trackState = _trackState.copyWith(asmsTracks: response.tracks ?? []);
      }

      /// Load subtitles
      if (betterPlayerDataSource?.useAsmsSubtitles == true) {
        final asmsSubtitles = response.subtitles ?? [];
        for (final asmsSubtitle in asmsSubtitles) {
          _subtitleState = _subtitleState.copyWith(subtitlesSourceList: [
            ..._subtitleState.subtitlesSourceList,
            PlayerSubtitlesSource(
              type: PlayerSubtitlesSourceType.network,
              name: asmsSubtitle.name,
              urls: asmsSubtitle.realUrls,
              asmsIsSegmented: asmsSubtitle.isSegmented,
              asmsSegmentsTime: asmsSubtitle.segmentsTime,
              asmsSegments: asmsSubtitle.segments,
              selectedByDefault: asmsSubtitle.isDefault,
            ),
          ]);
        }
      }

      ///Load audio tracks
      if (betterPlayerDataSource?.useAsmsAudioTracks == true &&
          _isDataSourceAsms(betterPlayerDataSource!)) {
        _trackState = _trackState.copyWith(
          asmsAudioTracks: response.audios ?? [],
        );
        if (_trackState.asmsAudioTracks.isNotEmpty) {
          setAudioTrack(_trackState.asmsAudioTracks.first);
        }
      }
    }
  }

  ///Internal method which invokes _engine source setup.
  Future _setupDataSource(PlayerDataSource betterPlayerDataSource) async {
    switch (betterPlayerDataSource.type) {
      case DataSourceType.network:
        await _engine?.setNetworkDataSource(
          betterPlayerDataSource.url,
          headers: _getHeaders(),
          useCache:
              _betterPlayerDataSource!.cacheConfiguration?.useCache ?? false,
          maxCacheSize:
              _betterPlayerDataSource!.cacheConfiguration?.maxCacheSize ?? 0,
          maxCacheFileSize:
              _betterPlayerDataSource!.cacheConfiguration?.maxCacheFileSize ??
              0,
          cacheKey: _betterPlayerDataSource?.cacheConfiguration?.key,
          showNotification: _betterPlayerDataSource
              ?.notificationConfiguration
              ?.showNotification,
          title: _betterPlayerDataSource?.notificationConfiguration?.title,
          author: _betterPlayerDataSource?.notificationConfiguration?.author,
          imageUrl:
              _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
          notificationChannelName: _betterPlayerDataSource
              ?.notificationConfiguration
              ?.notificationChannelName,
          overriddenDuration: _betterPlayerDataSource!.overriddenDuration,
          formatHint: _betterPlayerDataSource!.videoFormat,
          licenseUrl: _betterPlayerDataSource?.drmConfiguration?.licenseUrl,
          certificateUrl:
              _betterPlayerDataSource?.drmConfiguration?.certificateUrl,
          drmHeaders: _betterPlayerDataSource?.drmConfiguration?.headers,
          activityName:
              _betterPlayerDataSource?.notificationConfiguration?.activityName,
          clearKey: _betterPlayerDataSource?.drmConfiguration?.clearKey,
          videoExtension: _betterPlayerDataSource!.videoExtension,
        );

      case DataSourceType.file:
        final file = File(betterPlayerDataSource.url);
        if (!file.existsSync()) {
          PlayerLogger.warning(
            message:
                "File ${file.path} doesn't exists. This may be because "
                "you're acessing file from native path and Flutter doesn't "
                'recognize this path.',
            textureId: textureId,
          );
        }

        await _engine?.setFileDataSource(
          File(betterPlayerDataSource.url),
          showNotification: _betterPlayerDataSource
              ?.notificationConfiguration
              ?.showNotification,
          title: _betterPlayerDataSource?.notificationConfiguration?.title,
          author: _betterPlayerDataSource?.notificationConfiguration?.author,
          imageUrl:
              _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
          notificationChannelName: _betterPlayerDataSource
              ?.notificationConfiguration
              ?.notificationChannelName,
          overriddenDuration: _betterPlayerDataSource!.overriddenDuration,
          activityName:
              _betterPlayerDataSource?.notificationConfiguration?.activityName,
          clearKey: _betterPlayerDataSource?.drmConfiguration?.clearKey,
        );
      case DataSourceType.memory:
        final file = await _createFile(
          _betterPlayerDataSource!.bytes!,
          extension: _betterPlayerDataSource!.videoExtension,
        );

        if (file.existsSync()) {
          await _engine?.setFileDataSource(
            file,
            showNotification: _betterPlayerDataSource
                ?.notificationConfiguration
                ?.showNotification,
            title: _betterPlayerDataSource?.notificationConfiguration?.title,
            author: _betterPlayerDataSource?.notificationConfiguration?.author,
            imageUrl:
                _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
            notificationChannelName: _betterPlayerDataSource
                ?.notificationConfiguration
                ?.notificationChannelName,
            overriddenDuration: _betterPlayerDataSource!.overriddenDuration,
            activityName: _betterPlayerDataSource
                ?.notificationConfiguration
                ?.activityName,
            clearKey: _betterPlayerDataSource?.drmConfiguration?.clearKey,
          );
          _tempFiles.add(file);
        } else {
          throw ArgumentError("Couldn't create file from memory.");
        }

      default:
        throw UnimplementedError(
          '${betterPlayerDataSource.type} is not implemented',
        );
    }
    await _initializeVideo();
  }

  ///Create file from provided list of bytes. File will be created in temporary
  ///directory.
  Future<File> _createFile(
    List<int> bytes, {
    String? extension = 'temp',
  }) async {
    final dir = (await getTemporaryDirectory()).path;
    final temp = File(
      '$dir/better_player_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await temp.writeAsBytes(bytes);
    return temp;
  }

  ///Initializes video based on configuration. Invoke actions which need to be
  ///run on player start.
  Future _initializeVideo() async {
    PlayerLogger.info(
      message:
          'Initializing video: autoPlay=${betterPlayerConfiguration.autoPlay}, '
          'startAt=${betterPlayerConfiguration.startAt}',
      textureId: textureId,
    );
    setLooping(betterPlayerConfiguration.looping);
    _videoEventStreamSubscription?.cancel();
    _videoEventStreamSubscription = null;

    _videoEventStreamSubscription = _engine?.videoEventStreamController.stream
        .listen(_handleVideoEvent);

    final fullScreenByDefault = betterPlayerConfiguration.fullScreenByDefault;
    if (betterPlayerConfiguration.autoPlay) {
      if (fullScreenByDefault && !isFullScreen) {
        enterFullScreen();
      }
      if (_isAutomaticPlayPauseHandled()) {
        if (_playbackState.appLifecycleState == AppLifecycleState.resumed &&
            _viewState.isPlayerVisible) {
          await play();
        } else {
          _playbackState = _playbackState.copyWith(wasPlayingBeforePause: true);
        }
      } else {
        await play();
      }
    } else {
      if (fullScreenByDefault) {
        enterFullScreen();
      }
    }

    final startAt = betterPlayerConfiguration.startAt;
    if (startAt != null) {
      seekTo(startAt);
    }
  }

  ///Retry data source if playback failed.
  Future retryDataSource() async {
    PlayerLogger.warning(
      message: 'Retrying data source',
      textureId: textureId,
    );
    await _setupDataSource(_betterPlayerDataSource!);
    if (_playbackState.videoPlayerValueOnError != null) {
      final position = _playbackState.videoPlayerValueOnError!.position;
      await seekTo(position);
      await play();
      _playbackState = _playbackState.copyWith(
        clearVideoPlayerValueOnError: true,
      );
    }
  }

  ///Build headers map that will be used to setup video player controller. Apply
  ///DRM headers if available.
  Map<String, String?> _getHeaders() {
    final headers = betterPlayerDataSource!.headers ?? {};
    if (betterPlayerDataSource?.drmConfiguration?.drmType == DrmType.token &&
        betterPlayerDataSource?.drmConfiguration?.token != null) {
      headers[PlayerEventConstants.authorizationHeader] =
          betterPlayerDataSource!.drmConfiguration!.token!;
    }
    return headers;
  }

  ///Flag which determines whenever player is playing live data source.
  bool isLiveStream() {
    if (_betterPlayerDataSource == null) {
      PlayerLogger.warning(
        message: 'The data source has not been initialized',
        textureId: textureId,
      );
      throw StateError('The data source has not been initialized');
    }
    return _betterPlayerDataSource!.liveStream == true;
  }

  ///Flag which determines whenever player data source has been initialized.
  bool? isVideoInitialized() {
    if (_engine == null) {
      PlayerLogger.warning(
        message: 'The data source has not been initialized',
        textureId: textureId,
      );
      throw StateError('The data source has not been initialized');
    }
    return _engine?.value.initialized;
  }
}
