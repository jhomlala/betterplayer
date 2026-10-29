import 'dart:async';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/player_cupertino_localizations_delegate.dart';
import 'package:better_player/src/controls/player_material_localizations_delegate.dart';
import 'package:better_player/src/controls/player_material_progress_bar.dart';
import 'package:better_player/src/controls/player_web_error_widget.dart';
import 'package:better_player/src/controls/player_web_settings_menu.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class PlayerWebControls extends StatefulWidget {
  const PlayerWebControls({
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
    super.key,
  });

  final Function(bool visbility) onControlsVisibilityChanged;
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  State<PlayerWebControls> createState() => _PlayerWebControlsState();
}

class _PlayerWebControlsState
    extends BetterPlayerControlsState<PlayerWebControls> {
  BetterPlayerController? _betterPlayerController;
  Timer? _hideTimer;
  bool _controlsNotVisible = true;
  VideoPlayerValue? _latestValue;
  String? _errorDescription;
  bool _isMenuOpen = false;
  bool _isPipSupported = false;
  StreamSubscription<bool>? _controlsVisibilitySubscription;
  final FocusNode _focusNode = FocusNode();

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  PlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      widget.controlsConfiguration;

  @override
  void didChangeDependencies() {
    final oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    if (oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }
    super.didChangeDependencies();
  }

  void _initialize() {
    _betterPlayerController!.addEventsListener(_onPlayerEvent);
    _betterPlayerController!.addVideoListener(_updateState);
    _checkPipSupport();
    _controlsVisibilitySubscription = _betterPlayerController!
        .controlsVisibilityStream
        .listen((visibility) {
          if (!mounted) {
            return;
          }
          if (visibility) {
            cancelAndRestartTimer();
          } else {
            _hideTimer?.cancel();
            if (!_controlsNotVisible) {
              setState(() {
                _controlsNotVisible = true;
              });
              widget.onControlsVisibilityChanged(false);
            }
          }
        });
    _latestValue = _betterPlayerController!.videoPlayerValue;
    final showOnInitialize =
        widget.controlsConfiguration.showControlsOnInitialize ||
        _betterPlayerController!.controlsAlwaysVisible;
    _controlsNotVisible = !showOnInitialize;
    if (showOnInitialize) {
      _startHideTimer();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onControlsVisibilityChanged(showOnInitialize);
      }
    });
  }

  Future<void> _checkPipSupport() async {
    try {
      final supported =
          await _betterPlayerController?.isPictureInPictureSupported() ?? false;
      if (mounted && _isPipSupported != supported) {
        setState(() {
          _isPipSupported = supported;
        });
      }
    } catch (_) {
      // Data source may not be initialized yet.
    }
  }

  void _dispose() {
    _betterPlayerController?.removeEventsListener(_onPlayerEvent);
    _betterPlayerController?.removeVideoListener(_updateState);
    _controlsVisibilitySubscription?.cancel();
    _hideTimer?.cancel();
  }

  @override
  void dispose() {
    _dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPlayerEvent(PlayerEvent event) {
    if (mounted) {
      if (event.betterPlayerEventType == PlayerEventType.exception) {
        setState(() {
          _errorDescription = event.parameters?['exception'] as String?;
        });
      } else if (event.betterPlayerEventType ==
          PlayerEventType.setupDataSource) {
        setState(() {
          _errorDescription = null;
        });
        _checkPipSupport();
      }

      _updateState();
      if (event.betterPlayerEventType == PlayerEventType.finished) {
        cancelAndRestartTimer();
      }
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _latestValue = _betterPlayerController?.videoPlayerValue;
      });
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController?.controlsAlwaysVisible == true) {
      return;
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.controlsConfiguration.controlsHideTime, () {
      if (_betterPlayerController?.controlsAlwaysVisible == true) {
        return;
      }
      if (mounted && !_isMenuOpen) {
        final wasVisible = !_controlsNotVisible;
        if (wasVisible) {
          setState(() {
            _controlsNotVisible = true;
          });
          widget.onControlsVisibilityChanged(false);
        }
      }
    });
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    if (mounted) {
      final wasNotVisible = _controlsNotVisible;
      setState(() {
        _controlsNotVisible = false;
      });
      if (wasNotVisible) {
        widget.onControlsVisibilityChanged(true);
      }
    }
    _startHideTimer();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      return _handleVolumeAndSeek(event.logicalKey);
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleVolumeAndSeek(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
      if (widget.controlsConfiguration.enablePlayPause) {
        _onPlayPause();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      cancelAndRestartTimer();
      if (_latestValue?.initialized == true) {
        final position = _latestValue?.position;
        if (position != null) {
          unawaited(
            _betterPlayerController
                ?.seekTo(position - const Duration(seconds: 10))
                .catchError((_) {}),
          );
        }
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      cancelAndRestartTimer();
      if (_latestValue?.initialized == true) {
        final position = _latestValue?.position;
        if (position != null) {
          unawaited(
            _betterPlayerController
                ?.seekTo(position + const Duration(seconds: 10))
                .catchError((_) {}),
          );
        }
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      cancelAndRestartTimer();
      final volume = (_latestValue?.volume ?? 1.0) + 0.1;
      unawaited(
        _betterPlayerController
            ?.setVolume(volume.clamp(0.0, 1.0))
            .catchError((_) {}),
      );
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      cancelAndRestartTimer();
      final volume = (_latestValue?.volume ?? 1.0) - 0.1;
      unawaited(
        _betterPlayerController
            ?.setVolume(volume.clamp(0.0, 1.0))
            .catchError((_) {}),
      );
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyM) {
      cancelAndRestartTimer();
      if (widget.controlsConfiguration.enableMute) {
        final isMuted = _latestValue?.volume == 0;
        unawaited(
          _betterPlayerController
              ?.setVolume(isMuted ? 1 : 0)
              .catchError((_) {}),
        );
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyF) {
      cancelAndRestartTimer();
      if (widget.controlsConfiguration.enableFullscreen) {
        _betterPlayerController?.toggleFullScreen();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPlayPause() {
    cancelAndRestartTimer();
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    if (_latestValue?.isPlaying == true) {
      unawaited(_betterPlayerController?.pause().catchError((_) {}));
    } else {
      if (_latestValue?.position != null &&
          _latestValue?.duration != null &&
          _latestValue!.position >= _latestValue!.duration!) {
        unawaited(
          _betterPlayerController?.seekTo(Duration.zero).catchError((_) {}),
        );
      }
      unawaited(_betterPlayerController?.play().catchError((_) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      delegates: [
        PlayerMaterialLocalizationsDelegate(
          _betterPlayerController?.translations ?? PlayerTranslations(),
        ),
        PlayerCupertinoLocalizationsDelegate(
          _betterPlayerController?.translations ?? PlayerTranslations(),
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          type: MaterialType.transparency,
          child: Builder(
            builder: (BuildContext context) {
              if (_betterPlayerController == null ||
                  !_betterPlayerController!.controlsEnabled) {
                return const SizedBox();
              }

              if (_latestValue?.hasError == true || _errorDescription != null) {
                return ColoredBox(
                  color: Colors.black,
                  child: PlayerWebErrorWidget(
                    controlsConfiguration: widget.controlsConfiguration,
                    errorDescription: _errorDescription,
                  ),
                );
              }

              return MouseRegion(
                onHover: (_) => cancelAndRestartTimer(),
                onExit: (_) {
                  if (!_betterPlayerController!.controlsAlwaysVisible &&
                      !_isMenuOpen) {
                    _startHideTimer();
                  }
                },
                child: Focus(
                  focusNode: _focusNode,
                  autofocus: true,
                  onKeyEvent: _onKeyEvent,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _focusNode.requestFocus();
                          if (_isMenuOpen) {
                            setState(() {
                              _isMenuOpen = false;
                            });
                            cancelAndRestartTimer();
                            return;
                          }
                          if (widget.controlsConfiguration.enablePlayPause) {
                            _onPlayPause();
                          }
                        },
                        onDoubleTap:
                            widget.controlsConfiguration.enableFullscreen
                            ? () => _betterPlayerController?.toggleFullScreen()
                            : null,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand(),
                      ),
                      // Controls overlay
                      AnimatedOpacity(
                        opacity: _controlsNotVisible ? 0.0 : 1.0,
                        duration:
                            widget.controlsConfiguration.controlsTransitionTime,
                        child: IgnorePointer(
                          ignoring: _controlsNotVisible,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Gradient background for bottom controls
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black87,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_betterPlayerController!
                                              .isLiveStream() &&
                                          widget
                                              .controlsConfiguration
                                              .enableProgressBar) ...[
                                        _PlayerWebProgressBar(
                                          controller: _betterPlayerController,
                                          configuration:
                                              widget.controlsConfiguration,
                                          onDragStart: () =>
                                              _hideTimer?.cancel(),
                                          onDragEnd: cancelAndRestartTimer,
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      _PlayerWebBottomBar(
                                        controller: _betterPlayerController,
                                        configuration:
                                            widget.controlsConfiguration,
                                        isPipSupported: _isPipSupported,
                                        onPlayPause: _onPlayPause,
                                        onMenuToggle: _onMenuToggle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isMenuOpen) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isMenuOpen = false;
                            });
                            cancelAndRestartTimer();
                          },
                          child: const SizedBox.expand(),
                        ),
                        Positioned(
                          top: 8,
                          right: 16,
                          bottom:
                              widget.controlsConfiguration.controlBarHeight + 8,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: PlayerWebSettingsMenu(
                              controller: _betterPlayerController!,
                              controlsConfiguration:
                                  widget.controlsConfiguration,
                              isAboutMenuVisible: isAboutMenuVisible,
                              onClose: () {
                                setState(() {
                                  _isMenuOpen = false;
                                });
                                cancelAndRestartTimer();
                              },
                              onShowAbout: showPlayerAboutDialog,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onMenuToggle() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _controlsNotVisible = false;
      }
    });
    if (_isMenuOpen) {
      _hideTimer?.cancel();
      widget.onControlsVisibilityChanged(true);
    } else {
      cancelAndRestartTimer();
    }
  }
}

class _PlayerWebProgressBar extends StatefulWidget {
  const _PlayerWebProgressBar({
    required this.controller,
    required this.configuration,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final BetterPlayerController? controller;
  final PlayerControlsConfiguration configuration;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  @override
  State<_PlayerWebProgressBar> createState() => _PlayerWebProgressBarState();
}

class _PlayerWebProgressBarState extends State<_PlayerWebProgressBar> {
  double? _hoverPosition;
  Duration? _hoverDuration;

  @override
  Widget build(BuildContext context) {
    final latestValue = widget.controller?.videoPlayerValue;
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) {
            final duration = latestValue?.duration;
            if (duration != null) {
              final x = event.localPosition.dx;
              final percent = (x / constraints.maxWidth).clamp(0.0, 1.0);
              setState(() {
                _hoverPosition = x;
                _hoverDuration = Duration(
                  milliseconds: (percent * duration.inMilliseconds).toInt(),
                );
              });
            }
          },
          onExit: (_) {
            setState(() {
              _hoverPosition = null;
              _hoverDuration = null;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(
                label: 'better_player_material_progress_bar',
                identifier: 'better_player_material_progress_bar',
                child: SizedBox(
                  height: 12,
                  child: PlayerMaterialVideoProgressBar(
                    widget.controller,
                    onDragStart: widget.onDragStart,
                    onDragEnd: widget.onDragEnd,
                    colors: PlayerProgressColors(
                      playedColor: widget.configuration.progressBarPlayedColor,
                      handleColor: widget.configuration.progressBarHandleColor,
                      bufferedColor:
                          widget.configuration.progressBarBufferedColor,
                      backgroundColor:
                          widget.configuration.progressBarBackgroundColor,
                    ),
                  ),
                ),
              ),
              if (_hoverPosition != null && _hoverDuration != null)
                Positioned(
                  bottom: 20,
                  left: _hoverPosition! - 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      PlayerUiUtils.formatDuration(_hoverDuration!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerWebBottomBar extends StatefulWidget {
  const _PlayerWebBottomBar({
    required this.controller,
    required this.configuration,
    required this.onPlayPause,
    required this.onMenuToggle,
    this.isPipSupported = false,
  });

  final BetterPlayerController? controller;
  final PlayerControlsConfiguration configuration;
  final VoidCallback onPlayPause;
  final VoidCallback onMenuToggle;
  final bool isPipSupported;

  @override
  State<_PlayerWebBottomBar> createState() => _PlayerWebBottomBarState();
}

class _PlayerWebBottomBarState extends State<_PlayerWebBottomBar> {
  bool _isVolumeHovered = false;

  @override
  Widget build(BuildContext context) {
    final latestValue = widget.controller?.videoPlayerValue;
    final isPlaying = latestValue?.isPlaying == true;
    final isMuted = latestValue?.volume == 0;

    return SizedBox(
      height: widget.configuration.controlBarHeight,
      child: Row(
        children: [
          if (widget.configuration.enablePlayPause)
            Semantics(
              label: 'better_player_material_controls_play_pause_button',
              identifier: 'better_player_material_controls_play_pause_button',
              child: IconButton(
                tooltip: isPlaying
                    ? widget.controller!.translations.controlsPauseLabel
                    : widget.controller!.translations.controlsPlayLabel,
                icon: Icon(
                  isPlaying
                      ? widget.configuration.pauseIcon
                      : widget.configuration.playIcon,
                  color: widget.configuration.iconsColor,
                ),
                onPressed: widget.onPlayPause,
              ),
            ),
          if (widget.configuration.enableMute)
            MouseRegion(
              onEnter: (_) => setState(() => _isVolumeHovered = true),
              onExit: (_) => setState(() => _isVolumeHovered = false),
              child: Row(
                children: [
                  Semantics(
                    label: 'better_player_material_controls_mute_button',
                    identifier: 'better_player_material_controls_mute_button',
                    child: IconButton(
                      tooltip: isMuted
                          ? widget.controller!.translations.controlsUnmuteLabel
                          : widget.controller!.translations.controlsMuteLabel,
                      icon: Icon(
                        isMuted
                            ? widget.configuration.unMuteIcon
                            : widget.configuration.muteIcon,
                        color: widget.configuration.iconsColor,
                      ),
                      onPressed: () {
                        if (isMuted) {
                          widget.controller?.setVolume(1);
                        } else {
                          widget.controller?.setVolume(0);
                        }
                      },
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isVolumeHovered ? 100.0 : 0.0,
                    child: ClipRect(
                      child: OverflowBox(
                        minWidth: 100,
                        maxWidth: 100,
                        minHeight: 40,
                        maxHeight: 40,
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              activeTrackColor: widget.configuration.iconsColor,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: widget.configuration.iconsColor,
                            ),
                            child: Slider(
                              value: latestValue?.volume ?? 1.0,
                              onChanged: (val) {
                                widget.controller?.setVolume(val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.controller?.isLiveStream() == true) ...[
            const SizedBox(width: 8),
            Text(
              widget.controller!.translations.controlsLive,
              style: TextStyle(
                color: widget.configuration.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else if (widget.configuration.enableProgressText) ...[
            const SizedBox(width: 8),
            Text(
              '${PlayerUiUtils.formatDuration(latestValue?.position ?? Duration.zero)} / ${PlayerUiUtils.formatDuration(latestValue?.duration ?? Duration.zero)}',
              style: TextStyle(
                color: widget.configuration.textColor,
                fontSize: 14,
              ),
            ),
          ],
          const Spacer(),
          if (widget.configuration.enableAirPlay)
            _PlayerWebAirPlayButton(
              controller: widget.controller,
              configuration: widget.configuration,
            ),
          if (widget.isPipSupported &&
              widget.configuration.enablePip &&
              widget.controller?.isLiveStream() == false &&
              widget.controller?.betterPlayerGlobalKey != null)
            Semantics(
              label: 'better_player_material_controls_pip_button',
              identifier: 'better_player_material_controls_pip_button',
              container: true,
              button: true,
              child: IconButton(
                tooltip:
                    widget.controller?.translations.controlsPipLabel ??
                    'Picture in Picture',
                icon: Icon(
                  widget.configuration.pipMenuIcon,
                  color: widget.configuration.iconsColor,
                ),
                onPressed: () {
                  final globalKey = widget.controller?.betterPlayerGlobalKey;
                  if (globalKey != null) {
                    widget.controller?.enablePictureInPicture(globalKey);
                  }
                },
              ),
            ),
          if (widget.configuration.enableOverflowMenu)
            Semantics(
              label: 'better_player_material_controls_more_button',
              identifier: 'better_player_material_controls_more_button',
              container: true,
              button: true,
              child: IconButton(
                tooltip: 'Settings',
                icon: Icon(
                  widget.configuration.overflowMenuIcon,
                  color: widget.configuration.iconsColor,
                ),
                onPressed: widget.onMenuToggle,
              ),
            ),
          if (widget.configuration.enableFullscreen)
            Semantics(
              label: 'better_player_material_controls_fullscreen_button',
              identifier: 'better_player_material_controls_fullscreen_button',
              child: IconButton(
                icon: Icon(
                  widget.controller?.isFullScreen == true
                      ? widget.configuration.fullscreenDisableIcon
                      : widget.configuration.fullscreenEnableIcon,
                  color: widget.configuration.iconsColor,
                ),
                onPressed: () => widget.controller?.toggleFullScreen(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerWebAirPlayButton extends StatelessWidget {
  const _PlayerWebAirPlayButton({
    required this.controller,
    required this.configuration,
  });

  final BetterPlayerController? controller;
  final PlayerControlsConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox();
    final isCasting = controller!.isCasting;
    final isAirPlayActive = controller!.isAirPlayActive;
    final isActive = isCasting || isAirPlayActive;

    final IconData icon;
    if (isCasting) {
      icon = isActive
          ? configuration.castConnectedIcon
          : configuration.castIcon;
    } else {
      icon = isActive
          ? configuration.airPlayActiveIcon
          : configuration.airPlayIcon;
    }

    final label = isCasting
        ? controller!.translations.controlsCastLabel
        : controller!.translations.controlsAirPlayLabel;

    return Semantics(
      label: 'better_player_web_controls_airplay_button',
      identifier: 'better_player_web_controls_airplay_button',
      container: true,
      button: true,
      child: IconButton(
        tooltip: label,
        icon: Icon(
          icon,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : configuration.iconsColor,
        ),
        onPressed: controller!.showExternalPlaybackPicker,
      ),
    );
  }
}
