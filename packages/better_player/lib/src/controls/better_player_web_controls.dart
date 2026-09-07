import 'dart:async';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/controls/better_player_web_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _BetterPlayerMenuOption {
  subtitles,
  quality,
  playbackSpeed,
  audioTracks,
}

class BetterPlayerWebControls extends StatefulWidget {
  const BetterPlayerWebControls({
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
    super.key,
  });

  final Function(bool visbility) onControlsVisibilityChanged;
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  State<BetterPlayerWebControls> createState() =>
      _BetterPlayerWebControlsState();
}

class _BetterPlayerWebControlsState
    extends BetterPlayerControlsState<BetterPlayerWebControls> {
  BetterPlayerController? _betterPlayerController;
  Timer? _hideTimer;
  bool _controlsNotVisible = true;
  VideoPlayerValue? _latestValue;
  String? _errorDescription;
  bool _isMenuOpen = false;

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
    _latestValue = _betterPlayerController!.videoPlayerValue;
    _controlsNotVisible = !_betterPlayerController!.controlsAlwaysVisible;
    widget.onControlsVisibilityChanged(!_controlsNotVisible);
    if (_controlsNotVisible) {
      cancelAndRestartTimer();
    }
  }

  void _dispose() {
    _betterPlayerController?.removeEventsListener(_onPlayerEvent);
    _betterPlayerController?.removeVideoListener(_updateState);
    _hideTimer?.cancel();
  }

  @override
  void dispose() {
    _dispose();
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
      }

      _updateState();
      if (event.betterPlayerEventType == PlayerEventType.play ||
          event.betterPlayerEventType == PlayerEventType.pause) {
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

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    if (mounted) {
      setState(() {
        _controlsNotVisible = false;
        widget.onControlsVisibilityChanged(true);
      });
    }
    _hideTimer = Timer(widget.controlsConfiguration.controlsHideTime, () {
      if (_betterPlayerController?.controlsAlwaysVisible == true) {
        return;
      }
      if (mounted && !_isMenuOpen) {
        setState(() {
          _controlsNotVisible = true;
          widget.onControlsVisibilityChanged(false);
        });
      }
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      return _handleVolumeAndSeek(event.logicalKey);
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleVolumeAndSeek(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
      _onPlayPause();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      final position = _latestValue?.position;
      if (position != null) {
        _betterPlayerController?.seekTo(position - const Duration(seconds: 10));
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      final position = _latestValue?.position;
      if (position != null) {
        _betterPlayerController?.seekTo(position + const Duration(seconds: 10));
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      final volume = (_latestValue?.volume ?? 1.0) + 0.1;
      _betterPlayerController?.setVolume(volume.clamp(0.0, 1.0));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      final volume = (_latestValue?.volume ?? 1.0) - 0.1;
      _betterPlayerController?.setVolume(volume.clamp(0.0, 1.0));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyM) {
      final isMuted = _latestValue?.volume == 0;
      if (isMuted) {
        _betterPlayerController?.setVolume(1);
      } else {
        _betterPlayerController?.setVolume(0);
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyF) {
      _betterPlayerController?.toggleFullScreen();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPlayPause() {
    if (_latestValue?.isPlaying == true) {
      _betterPlayerController?.pause();
    } else {
      if (_latestValue?.position != null &&
          _latestValue?.duration != null &&
          _latestValue!.position >= _latestValue!.duration!) {
        _betterPlayerController?.seekTo(Duration.zero);
      }
      _betterPlayerController?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (BuildContext context) {
          if (_betterPlayerController == null) return const SizedBox();

          if (_latestValue?.hasError == true || _errorDescription != null) {
            return ColoredBox(
              color: Colors.black,
              child: BetterPlayerWebErrorWidget(
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
                _hideTimer?.cancel();
                setState(() {
                  _controlsNotVisible = true;
                  widget.onControlsVisibilityChanged(false);
                });
              }
            },
            child: Focus(
              onKeyEvent: _onKeyEvent,
              child: GestureDetector(
                onTap: _onPlayPause,
                onDoubleTap: () => _betterPlayerController?.toggleFullScreen(),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Controls overlay
                    AnimatedOpacity(
                      opacity: _controlsNotVisible ? 0.0 : 1.0,
                      duration: widget.controlsConfiguration.controlsHideTime,
                      child: IgnorePointer(
                        ignoring: _controlsNotVisible,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Gradient background for bottom controls
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_betterPlayerController!
                                      .isLiveStream()) ...[
                                    _BetterPlayerWebProgressBar(
                                      controller: _betterPlayerController,
                                      configuration:
                                          widget.controlsConfiguration,
                                      onDragStart: () => _hideTimer?.cancel(),
                                      onDragEnd: cancelAndRestartTimer,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  _BetterPlayerWebBottomBar(
                                    controller: _betterPlayerController,
                                    configuration: widget.controlsConfiguration,
                                    onPlayPause: _onPlayPause,
                                    onMenuToggle: () =>
                                        setState(() => _isMenuOpen = true),
                                    onMenuClose: () {
                                      setState(() => _isMenuOpen = false);
                                      cancelAndRestartTimer();
                                    },
                                    settingsMenu: _buildSettingsMenu(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Semantics(
      label: 'better_player_material_controls_more_button',
      identifier: 'better_player_material_controls_more_button',
      child: PopupMenuButton<_BetterPlayerMenuOption>(
        icon: Icon(
          widget.controlsConfiguration.overflowMenuIcon,
          color: widget.controlsConfiguration.iconsColor,
        ),
        color: const Color(0xFF212121),
        offset: const Offset(0, -50),
        tooltip: 'Settings',
        onOpened: () {
          _isMenuOpen = true;
        },
        onCanceled: () {
          _isMenuOpen = false;
          cancelAndRestartTimer();
        },
        onSelected: (value) async {
          if (value == _BetterPlayerMenuOption.playbackSpeed) {
            await _showSpeedMenu();
          } else if (value == _BetterPlayerMenuOption.quality) {
            await _showQualityMenu();
          } else if (value == _BetterPlayerMenuOption.audioTracks) {
            await _showAudioMenu();
          } else if (value == _BetterPlayerMenuOption.subtitles) {
            await _showSubtitlesMenu();
          }

          _isMenuOpen = false;
          cancelAndRestartTimer();
        },
        itemBuilder: (context) {
          return [
            if (widget.controlsConfiguration.enableSubtitles)
              PopupMenuItem(
                value: _BetterPlayerMenuOption.subtitles,
                child: Semantics(
                  label: 'better_player_overflow_menu_subtitles',
                  identifier: 'better_player_overflow_menu_subtitles',
                  child: _BetterPlayerWebMenuRow(
                    _betterPlayerController!.translations.overflowMenuSubtitles,
                    _betterPlayerController!
                            .betterPlayerSubtitlesSource
                            ?.name ??
                        _betterPlayerController!.translations.generalNone,
                    Icons.subtitles,
                    widget.controlsConfiguration,
                  ),
                ),
              ),
            if (widget.controlsConfiguration.enableQualities)
              PopupMenuItem(
                value: _BetterPlayerMenuOption.quality,
                child: Semantics(
                  label: 'better_player_overflow_menu_quality',
                  identifier: 'better_player_overflow_menu_quality',
                  child: _BetterPlayerWebMenuRow(
                    'Resolution',
                    _getResolutionLabel(),
                    Icons.tune,
                    widget.controlsConfiguration,
                  ),
                ),
              ),
            if (widget.controlsConfiguration.enableAudioTracks)
              PopupMenuItem(
                value: _BetterPlayerMenuOption.audioTracks,
                child: Semantics(
                  label: 'better_player_overflow_menu_audio_tracks',
                  identifier: 'better_player_overflow_menu_audio_tracks',
                  child: _BetterPlayerWebMenuRow(
                    'Language',
                    _betterPlayerController!
                            .betterPlayerAsmsAudioTrack
                            ?.label ??
                        _betterPlayerController!.translations.generalDefault,
                    Icons.language,
                    widget.controlsConfiguration,
                  ),
                ),
              ),
            if (widget.controlsConfiguration.enablePlaybackSpeed)
              PopupMenuItem(
                value: _BetterPlayerMenuOption.playbackSpeed,
                child: Semantics(
                  label: 'better_player_overflow_menu_playback_speed',
                  identifier: 'better_player_overflow_menu_playback_speed',
                  child: _BetterPlayerWebMenuRow(
                    'Playback speed',
                    '${_latestValue?.speed ?? 1.0}x',
                    Icons.slow_motion_video,
                    widget.controlsConfiguration,
                  ),
                ),
              ),
          ];
        },
      ),
    );
  }

  Future<void> _showSpeedMenu() async {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final value = await _showSubMenu<double>(
      speeds
          .map(
            (s) => PopupMenuItem<double>(
              value: s,
              child: Semantics(
                label: 'better_player_overflow_menu_speed_$s',
                identifier: 'better_player_overflow_menu_speed_$s',
                child: _BetterPlayerWebCheckRow(
                  '${s}x',
                  _latestValue?.speed == s,
                  widget.controlsConfiguration,
                ),
              ),
            ),
          )
          .toList(),
    );
    if (value != null) _betterPlayerController?.setSpeed(value);
  }

  String _getResolutionLabel() {
    final asmsTrack = _betterPlayerController?.betterPlayerAsmsTrack;
    if (asmsTrack != null) {
      if ((asmsTrack.width ?? 0) == 0 && (asmsTrack.height ?? 0) == 0) {
        return _betterPlayerController!.translations.qualityAuto;
      }
      return '${asmsTrack.height}p';
    }
    final resolutions =
        _betterPlayerController?.betterPlayerDataSource?.resolutions;
    if (resolutions != null && resolutions.isNotEmpty) {
      final currentUrl = _betterPlayerController?.betterPlayerDataSource?.url;
      for (final entry in resolutions.entries) {
        if (entry.value == currentUrl) {
          return entry.key;
        }
      }
      return resolutions.keys.first;
    }
    return _betterPlayerController!.translations.qualityAuto;
  }

  Future<void> _showQualityMenu() async {
    final resolutions =
        _betterPlayerController?.betterPlayerDataSource?.resolutions;
    if (resolutions != null && resolutions.isNotEmpty) {
      final currentUrl = _betterPlayerController?.betterPlayerDataSource?.url;
      final value = await _showSubMenu<String>(
        resolutions.entries.map((entry) {
          final isSelected = entry.value == currentUrl;
          return PopupMenuItem<String>(
            value: entry.value,
            child: Semantics(
              label: 'better_player_overflow_menu_quality_${entry.key}',
              identifier: 'better_player_overflow_menu_quality_${entry.key}',
              child: _BetterPlayerWebCheckRow(
                entry.key,
                isSelected,
                widget.controlsConfiguration,
              ),
            ),
          );
        }).toList(),
      );
      if (value != null) {
        _betterPlayerController?.setResolution(value);
      }
    } else {
      final tracks = _betterPlayerController?.betterPlayerAsmsTracks ?? [];
      var index = 0;
      final items = tracks.map((t) {
        final isAuto = (t.width ?? 0) == 0 && (t.height ?? 0) == 0;
        final label = isAuto
            ? _betterPlayerController!.translations.qualityAuto
            : '${t.height}p';
        final isSelected = _betterPlayerController?.betterPlayerAsmsTrack == t;
        final identifier = isAuto
            ? 'better_player_overflow_menu_quality_auto'
            : 'better_player_overflow_menu_quality_$index';
        if (!isAuto) index++;
        return PopupMenuItem<PlayerAsmsTrack>(
          value: t,
          child: Semantics(
            label: identifier,
            identifier: identifier,
            child: _BetterPlayerWebCheckRow(
              label,
              isSelected,
              widget.controlsConfiguration,
            ),
          ),
        );
      }).toList();

      if (items.isEmpty) {
        items.add(
          PopupMenuItem<PlayerAsmsTrack>(
            value: PlayerAsmsTrack.defaultTrack(),
            child: Semantics(
              label: 'better_player_overflow_menu_quality_auto',
              identifier: 'better_player_overflow_menu_quality_auto',
              child: _BetterPlayerWebCheckRow(
                _betterPlayerController!.translations.qualityAuto,
                true,
                widget.controlsConfiguration,
              ),
            ),
          ),
        );
      }

      final value = await _showSubMenu<PlayerAsmsTrack>(items);
      if (value != null) {
        _betterPlayerController?.setTrack(value);
      }
    }
  }

  Future<void> _showAudioMenu() async {
    final tracks = _betterPlayerController?.betterPlayerAsmsAudioTracks ?? [];
    final items = tracks.map((t) {
      return PopupMenuItem<PlayerAsmsAudioTrack>(
        value: t,
        child: Semantics(
          label:
              'better_player_overflow_menu_audio_tracks_${t.id ?? 'unknown'}',
          identifier:
              'better_player_overflow_menu_audio_tracks_${t.id ?? 'unknown'}',
          child: _BetterPlayerWebCheckRow(
            t.label ?? 'Track ${t.id}',
            _betterPlayerController?.betterPlayerAsmsAudioTrack == t,
            widget.controlsConfiguration,
          ),
        ),
      );
    }).toList();

    if (items.isEmpty) {
      items.add(
        PopupMenuItem<PlayerAsmsAudioTrack>(
          value: PlayerAsmsAudioTrack(
            id: 0,
            label: _betterPlayerController!.translations.generalDefault,
          ),
          child: Semantics(
            label: 'better_player_overflow_menu_audio_tracks_default',
            identifier: 'better_player_overflow_menu_audio_tracks_default',
            child: _BetterPlayerWebCheckRow(
              _betterPlayerController!.translations.generalDefault,
              true,
              widget.controlsConfiguration,
            ),
          ),
        ),
      );
    }

    final value = await _showSubMenu<PlayerAsmsAudioTrack>(items);
    if (value != null) _betterPlayerController?.setAudioTrack(value);
  }

  Future<void> _showSubtitlesMenu() async {
    final subs = _betterPlayerController?.betterPlayerSubtitlesSourceList ?? [];
    final items = subs.map((s) {
      return PopupMenuItem<PlayerSubtitlesSource>(
        value: s,
        child: Semantics(
          label:
              'better_player_overflow_menu_subtitles_${s.type?.name ?? 'none'}',
          identifier:
              'better_player_overflow_menu_subtitles_${s.type?.name ?? 'none'}',
          child: _BetterPlayerWebCheckRow(
            s.name ?? 'Unknown',
            _betterPlayerController?.betterPlayerSubtitlesSource == s,
            widget.controlsConfiguration,
          ),
        ),
      );
    }).toList();

    if (items.isEmpty) {
      items.add(
        PopupMenuItem<PlayerSubtitlesSource>(
          value: PlayerSubtitlesSource(type: PlayerSubtitlesSourceType.none),
          child: Semantics(
            label: 'better_player_overflow_menu_subtitles_none',
            identifier: 'better_player_overflow_menu_subtitles_none',
            child: _BetterPlayerWebCheckRow(
              'None',
              true,
              widget.controlsConfiguration,
            ),
          ),
        ),
      );
    }

    final value = await _showSubMenu<PlayerSubtitlesSource>(items);
    if (value != null) _betterPlayerController?.setupSubtitleSource(value);
  }

  Future<T?> _showSubMenu<T>(List<PopupMenuEntry<T>> items) {
    return showMenu<T>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 1000, 0, 0),
      color: const Color(0xFF212121),
      items: items,
    );
  }
}

class _BetterPlayerWebCheckRow extends StatelessWidget {
  const _BetterPlayerWebCheckRow(
    this.title,
    this.isSelected,
    this.controlsConfiguration,
  );

  final String title;
  final bool isSelected;
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isSelected)
          Icon(
            Icons.check,
            color: controlsConfiguration.iconsColor,
            size: 16,
          )
        else
          const SizedBox(width: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(color: controlsConfiguration.textColor),
        ),
      ],
    );
  }
}

class _BetterPlayerWebMenuRow extends StatelessWidget {
  const _BetterPlayerWebMenuRow(
    this.title,
    this.value,
    this.icon,
    this.controlsConfiguration,
  );

  final String title;
  final String value;
  final IconData icon;
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: controlsConfiguration.iconsColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(color: controlsConfiguration.textColor),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: controlsConfiguration.textColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: controlsConfiguration.iconsColor,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }
}

class _BetterPlayerWebProgressBar extends StatefulWidget {
  const _BetterPlayerWebProgressBar({
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
  State<_BetterPlayerWebProgressBar> createState() =>
      _BetterPlayerWebProgressBarState();
}

class _BetterPlayerWebProgressBarState
    extends State<_BetterPlayerWebProgressBar> {
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
                  child: BetterPlayerMaterialVideoProgressBar(
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
                      BetterPlayerUiUtils.formatDuration(_hoverDuration!),
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

class _BetterPlayerWebBottomBar extends StatefulWidget {
  const _BetterPlayerWebBottomBar({
    required this.controller,
    required this.configuration,
    required this.onPlayPause,
    required this.onMenuToggle,
    required this.onMenuClose,
    required this.settingsMenu,
  });

  final BetterPlayerController? controller;
  final PlayerControlsConfiguration configuration;
  final VoidCallback onPlayPause;
  final VoidCallback onMenuToggle;
  final VoidCallback onMenuClose;
  final Widget settingsMenu;

  @override
  State<_BetterPlayerWebBottomBar> createState() =>
      _BetterPlayerWebBottomBarState();
}

class _BetterPlayerWebBottomBarState extends State<_BetterPlayerWebBottomBar> {
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
          const SizedBox(width: 8),
          if (widget.controller?.isLiveStream() == true)
            Text(
              widget.controller!.translations.controlsLive,
              style: TextStyle(
                color: widget.configuration.textColor,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              ' / ',
              style: TextStyle(
                color: widget.configuration.textColor,
                fontSize: 14,
              ),
            ),
          const Spacer(),
          if (widget.controller?.isLiveStream() == false)
            IconButton(
              icon: Icon(
                widget.configuration.pipMenuIcon,
                color: widget.configuration.iconsColor,
              ),
              onPressed: () => widget.controller?.enablePictureInPicture(
                widget.controller!.betterPlayerGlobalKey!,
              ),
            ),
          widget.settingsMenu,
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
