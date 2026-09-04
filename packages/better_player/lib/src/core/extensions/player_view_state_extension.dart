part of '../better_player_controller.dart';

extension PlayerViewStateExtension on BetterPlayerController {
  ///Method which is invoked when full screen changes.
  Future<void> _onFullScreenStateChanged() async {
    if (_engine?.value.isPlaying == true && !_viewState.isFullScreen) {
      enterFullScreen();
      _engine?.removeListener(_onFullScreenStateChanged);
    }
  }

  ///Enables full screen mode in player. This will trigger route change.
  void enterFullScreen() {
    _viewState = _viewState.copyWith(isFullScreen: true);
    _postControllerEvent(PlayerControllerEvent.openFullscreen);
  }

  ///Disables full screen mode in player. This will trigger route change.
  void exitFullScreen() {
    _viewState = _viewState.copyWith(isFullScreen: false);
    _postControllerEvent(PlayerControllerEvent.hideFullscreen);
  }

  ///Enables/disables full screen mode based on current fullscreen state.
  void toggleFullScreen() {
    _viewState = _viewState.copyWith(isFullScreen: !_viewState.isFullScreen);
    if (_viewState.isFullScreen) {
      _postControllerEvent(PlayerControllerEvent.openFullscreen);
    } else {
      _postControllerEvent(PlayerControllerEvent.hideFullscreen);
    }
  }

  ///Show or hide controls manually
  void setControlsVisibility(bool isVisible) {
    _controlsVisibilityStreamController.add(isVisible);
  }

  ///Enable/disable controls (when enabled = false, controls will be always hidden)
  void setControlsEnabled(bool enabled) {
    if (!enabled) {
      _controlsVisibilityStreamController.add(false);
    }
    _viewState = _viewState.copyWith(controlsEnabled: enabled);
  }

  ///Internal method, used to trigger CONTROLS_VISIBLE or CONTROLS_HIDDEN event
  ///once controls state changed.
  void toggleControlsVisibility(bool isVisible) {
    _postEvent(
      isVisible
          ? PlayerEvent(PlayerEventType.controlsVisible)
          : PlayerEvent(PlayerEventType.controlsHiddenEnd),
    );
  }

  ///Setup controls always visible mode
  void setControlsAlwaysVisible(bool controlsAlwaysVisible) {
    _viewState = _viewState.copyWith(
      controlsAlwaysVisible: controlsAlwaysVisible,
    );
    _controlsVisibilityStreamController.add(controlsAlwaysVisible);
  }

  ///Check if player can be played/paused automatically
  bool _isAutomaticPlayPauseHandled() {
    return !(_betterPlayerDataSource
                ?.notificationConfiguration
                ?.showNotification ==
            true) &&
        betterPlayerConfiguration.handleLifecycle;
  }

  ///Listener which handles state of player visibility. If player visibility is
  ///below 0.0 then video will be paused. When value is greater than 0, video
  ///will play again. If there's different handler of visibility then it will be
  ///used. If showNotification is set in data source or handleLifecycle is false
  /// then this logic will be ignored.
  Future<void> onPlayerVisibilityChanged(double visibilityFraction) async {
    _viewState = _viewState.copyWith(isPlayerVisible: visibilityFraction > 0);
    if (_disposed) {
      return;
    }
    _postEvent(PlayerEvent(PlayerEventType.changedPlayerVisibility));

    if (_isAutomaticPlayPauseHandled()) {
      if (betterPlayerConfiguration.playerVisibilityChangedBehavior != null) {
        betterPlayerConfiguration.playerVisibilityChangedBehavior!(
          visibilityFraction,
        );
      } else {
        if (visibilityFraction == 0) {
          _playbackState = _playbackState.copyWith(
              wasPlayingBeforePause:
                  _playbackState.wasPlayingBeforePause || isPlaying()!);
          pause();
        } else {
          if (_playbackState.wasPlayingBeforePause == true && !isPlaying()!) {
            play();
          }
        }
      }
    }
  }

  ///Set current lifecycle state. If state is [AppLifecycleState.resumed] then
  ///player starts playing again. if lifecycle is in [AppLifecycleState.paused]
  ///state, then video playback will stop. If showNotification is set in data
  ///source or handleLifecycle is false then this logic will be ignored.
  void setAppLifecycleState(AppLifecycleState appLifecycleState) {
    PlayerLogger.debug(
      message: 'App lifecycle: $appLifecycleState',
      textureId: textureId,
    );
    if (_isAutomaticPlayPauseHandled()) {
      _playbackState = _playbackState.copyWith(
        appLifecycleState: appLifecycleState,
      );
      if (appLifecycleState == AppLifecycleState.resumed) {
        if (_playbackState.wasPlayingBeforePause == true &&
            _viewState.isPlayerVisible) {
          play();
        }
      }
      if (appLifecycleState == AppLifecycleState.paused) {
        _playbackState = _playbackState.copyWith(
            wasPlayingBeforePause:
                _playbackState.wasPlayingBeforePause || isPlaying()!);
        pause();
      }
    }
  }

  ///Setup overridden aspect ratio.
  void setOverriddenAspectRatio(double aspectRatio) {
    _viewState = _viewState.copyWith(overriddenAspectRatio: aspectRatio);
  }

  ///Get aspect ratio used in current video. Returns the first non-null value
  ///from the following priority order: [_viewState.overriddenAspectRatio] ->
  ///[PlayerConfiguration.aspectRatio] -> the video player's actual aspect
  ///ratio ([_engine.value.aspectRatio]).
  ///If the video player is not initialized or the video size is not yet
  ///available, it returns null unless an override or configuration is set.
  double? getAspectRatio() {
    if (_viewState.overriddenAspectRatio != null) {
      return _viewState.overriddenAspectRatio;
    }
    if (betterPlayerConfiguration.aspectRatio != null) {
      return betterPlayerConfiguration.aspectRatio;
    }

    final videoValue = _engine?.value;
    if (videoValue != null && videoValue.size != null) {
      return videoValue.aspectRatio;
    }

    return null;
  }

  ///Setup overridden fit.
  void setOverriddenFit(BoxFit fit) {
    _viewState = _viewState.copyWith(overriddenFit: fit);
  }

  ///Get fit used in current video. If fit is null, then fit from
  ///PlayerConfiguration will be used. Otherwise [_viewState.overriddenFit] will be
  ///used.
  BoxFit getFit() {
    return _viewState.overriddenFit ?? betterPlayerConfiguration.fit;
  }

  ///Enable Picture in Picture (PiP) mode. [betterPlayerGlobalKey] is required
  ///to open PiP mode in iOS. When device is not supported, PiP mode won't be
  ///open.
  Future<void>? enablePictureInPicture(GlobalKey betterPlayerGlobalKey) async {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    final isPipSupported =
        (await _engine!.isPictureInPictureSupported()) ?? false;

    if (isPipSupported) {
      _viewState = _viewState.copyWith(
        wasInFullScreenBeforePiP: _viewState.isFullScreen,
      );
      _viewState = _viewState.copyWith(
        wasControlsEnabledBeforePiP: _viewState.controlsEnabled,
      );
      setControlsEnabled(false);
      if (defaultTargetPlatform == TargetPlatform.android) {
        _viewState = _viewState.copyWith(
          wasInFullScreenBeforePiP: _viewState.isFullScreen,
        );
        await _engine?.enablePictureInPicture(
          left: 0,
          top: 0,
          width: 0,
          height: 0,
        );
        enterFullScreen();
        _postEvent(PlayerEvent(PlayerEventType.pipStart));
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final renderBox =
            betterPlayerGlobalKey.currentContext!.findRenderObject()
                as RenderBox?;
        if (renderBox == null) {
          PlayerLogger.warning(
            message:
                "Can't show PiP. RenderBox is null. Did you provide valid global"
                ' key?',
            textureId: textureId,
          );
          return;
        }
        final position = renderBox.localToGlobal(Offset.zero);
        return _engine?.enablePictureInPicture(
          left: position.dx,
          top: position.dy,
          width: renderBox.size.width,
          height: renderBox.size.height,
        );
      } else {
        PlayerLogger.warning(
          message: 'Unsupported PiP in current platform.',
          textureId: textureId,
        );
      }
    } else {
      PlayerLogger.warning(
        message:
            "Picture in picture is not supported in this device. If you're "
            "using Android, please check if you're using activity v2 "
            'embedding.',
        textureId: textureId,
      );
    }
  }

  ///Disable Picture in Picture mode if it's enabled.
  Future<void>? disablePictureInPicture() {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    return _engine!.disablePictureInPicture();
  }

  ///Set GlobalKey of BetterPlayer. Used in PiP methods called from controls.
  void setBetterPlayerGlobalKey(GlobalKey betterPlayerGlobalKey) {
    _viewState = _viewState.copyWith(
      betterPlayerGlobalKey: betterPlayerGlobalKey,
    );
  }

  ///Check if picture in picture mode is supported in this device.
  Future<bool> isPictureInPictureSupported() async {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    final isPipSupported =
        (await _engine!.isPictureInPictureSupported()) ?? false;

    return isPipSupported && !_viewState.isFullScreen;
  }
}
