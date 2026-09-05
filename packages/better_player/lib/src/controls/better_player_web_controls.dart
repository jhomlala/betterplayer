import 'dart:async';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:flutter/material.dart';

class BetterPlayerWebControls extends StatefulWidget {
  const BetterPlayerWebControls({
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
    super.key,
  });

  final Function(bool visbility) onControlsVisibilityChanged;
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  State<BetterPlayerWebControls> createState() => _BetterPlayerWebControlsState();
}

class _BetterPlayerWebControlsState extends BetterPlayerControlsState<BetterPlayerWebControls> {
  BetterPlayerController? _betterPlayerController;
  Timer? _hideTimer;
  bool _controlsNotVisible = true;
  VideoPlayerValue? _latestValue;
  double? _latestVolume;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  PlayerControlsConfiguration get betterPlayerControlsConfiguration => widget.controlsConfiguration;

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
    _latestValue = _betterPlayerController!.videoPlayerValue;
    _controlsNotVisible = !_betterPlayerController!.controlsAlwaysVisible;
    widget.onControlsVisibilityChanged(!_controlsNotVisible);
    if (_controlsNotVisible) {
      cancelAndRestartTimer();
    }
  }

  void _dispose() {
    _betterPlayerController?.removeEventsListener(_onPlayerEvent);
    _hideTimer?.cancel();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _onPlayerEvent(PlayerEvent event) {
    if (mounted) {
      setState(() {
        _latestValue = _betterPlayerController?.videoPlayerValue;
      });
      if (event.betterPlayerEventType == PlayerEventType.play ||
          event.betterPlayerEventType == PlayerEventType.pause) {
        cancelAndRestartTimer();
      }
    }
  }

  bool _isMenuOpen = false;

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    if (mounted) {
      setState(() {
        _controlsNotVisible = false;
        widget.onControlsVisibilityChanged(true);
      });
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isMenuOpen) {
        setState(() {
          _controlsNotVisible = true;
          widget.onControlsVisibilityChanged(false);
        });
      }
    });
  }

  void _onPlayPause() {
    if (_latestValue?.isPlaying == true) {
      _betterPlayerController?.pause();
    } else {
      if (_latestValue?.position != null && _latestValue?.duration != null && _latestValue!.position >= _latestValue!.duration!) {
        _betterPlayerController?.seekTo(Duration.zero);
      }
      _betterPlayerController?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_betterPlayerController == null) return const SizedBox();

    return MouseRegion(
      onHover: (_) => cancelAndRestartTimer(),
      onExit: (_) {
        if (!_betterPlayerController!.controlsAlwaysVisible && !_isMenuOpen) {
          _hideTimer?.cancel();
          setState(() {
            _controlsNotVisible = true;
            widget.onControlsVisibilityChanged(false);
          });
        }
      },
      child: GestureDetector(
        onTap: _onPlayPause,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Controls overlay
            AnimatedOpacity(
              opacity: _controlsNotVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: _controlsNotVisible,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Gradient background for bottom controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          if (!_betterPlayerController!.isLiveStream()) ...[
                            _buildProgressBar(),
                            const SizedBox(height: 8),
                          ],
                          _buildBottomBar(),
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
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      height: 12,
      child: BetterPlayerMaterialVideoProgressBar(
        _betterPlayerController,
        onDragStart: () => _hideTimer?.cancel(),
        onDragEnd: cancelAndRestartTimer,
        colors: PlayerProgressColors(
          playedColor: widget.controlsConfiguration.progressBarPlayedColor,
          handleColor: widget.controlsConfiguration.progressBarHandleColor,
          bufferedColor: widget.controlsConfiguration.progressBarBufferedColor,
          backgroundColor: widget.controlsConfiguration.progressBarBackgroundColor,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isPlaying = _latestValue?.isPlaying == true;
    final isMuted = _latestValue?.volume == 0;

    return Row(
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? widget.controlsConfiguration.pauseIcon : widget.controlsConfiguration.playIcon,
            color: widget.controlsConfiguration.iconsColor,
          ),
          onPressed: _onPlayPause,
        ),
        IconButton(
          icon: Icon(
            isMuted ? widget.controlsConfiguration.muteIcon : widget.controlsConfiguration.unMuteIcon,
            color: widget.controlsConfiguration.iconsColor,
          ),
          onPressed: () {
            if (isMuted) {
              _betterPlayerController?.setVolume(_latestVolume ?? 1.0);
            } else {
              _latestVolume = _latestValue?.volume;
              _betterPlayerController?.setVolume(0);
            }
          },
        ),
        const SizedBox(width: 8),
        if (_betterPlayerController!.isLiveStream())
          Text(
            _betterPlayerController!.translations.controlsLive,
            style: TextStyle(
              color: widget.controlsConfiguration.liveTextColor,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            '${_formatDuration(_latestValue?.position)} / ${_formatDuration(_latestValue?.duration)}',
            style: TextStyle(color: widget.controlsConfiguration.textColor, fontSize: 14),
          ),
        const Spacer(),
        _buildSettingsMenu(),
        IconButton(
          icon: Icon(
            _betterPlayerController!.isFullScreen ? widget.controlsConfiguration.fullscreenDisableIcon : widget.controlsConfiguration.fullscreenEnableIcon,
            color: widget.controlsConfiguration.iconsColor,
          ),
          onPressed: () => _betterPlayerController?.toggleFullScreen(),
        ),
      ],
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  Widget _buildSettingsMenu() {
    return PopupMenuButton<String>(
      icon: Icon(widget.controlsConfiguration.overflowMenuIcon, color: widget.controlsConfiguration.iconsColor),
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
        if (value == 'speed') {
          await _showSpeedMenu();
        } else if (value == 'quality') {
          await _showQualityMenu();
        } else if (value == 'audio') {
          await _showAudioMenu();
        } else if (value == 'subtitles') {
          await _showSubtitlesMenu();
        }
        
        _isMenuOpen = false;
        cancelAndRestartTimer();
      },
      itemBuilder: (context) {
        return [
          if (_betterPlayerController!.betterPlayerSubtitlesSourceList.isNotEmpty == true)
            PopupMenuItem(
              value: 'subtitles',
              child: _buildMenuRow('Subtitles', _betterPlayerController!.betterPlayerSubtitlesSource?.name ?? 'Off', Icons.subtitles),
            ),
          if (_betterPlayerController!.betterPlayerAsmsTracks.isNotEmpty == true)
            PopupMenuItem(
              value: 'quality',
              child: _buildMenuRow('Resolution', '${_betterPlayerController!.betterPlayerAsmsTrack?.height ?? 'Auto'}', Icons.tune),
            ),
          if (_betterPlayerController!.betterPlayerAsmsAudioTracks.isNotEmpty == true)
            PopupMenuItem(
              value: 'audio',
              child: _buildMenuRow('Language', _betterPlayerController!.betterPlayerAsmsAudioTrack?.label ?? 'Default', Icons.language),
            ),
          PopupMenuItem(
            value: 'speed',
            child: _buildMenuRow('Playback speed', '${_latestValue?.speed ?? 1.0}x', Icons.slow_motion_video),
          ),
        ];
      },
    );
  }

  Widget _buildMenuRow(String title, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: widget.controlsConfiguration.iconsColor, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: widget.controlsConfiguration.textColor)),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Text(value, style: TextStyle(color: widget.controlsConfiguration.textColor, fontSize: 12)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: widget.controlsConfiguration.iconsColor, size: 16),
          ],
        ),
      ],
    );
  }

  Future<void> _showSpeedMenu() async {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final value = await _showSubMenu<double>(
      speeds.map((s) => PopupMenuItem<double>(value: s, child: _buildCheckRow('${s}x', _latestValue?.speed == s))).toList(),
    );
    if (value != null) _betterPlayerController?.setSpeed(value);
  }

  Future<void> _showQualityMenu() async {
    final tracks = _betterPlayerController?.betterPlayerAsmsTracks ?? [];
    final value = await _showSubMenu<PlayerAsmsTrack>(
      [
        PopupMenuItem<PlayerAsmsTrack>(
          value: PlayerAsmsTrack.defaultTrack(),
          child: _buildCheckRow('Auto', _betterPlayerController?.betterPlayerAsmsTrack?.width == 0),
        ),
        ...tracks.map((t) => PopupMenuItem<PlayerAsmsTrack>(
          value: t,
          child: _buildCheckRow('${t.height}p', _betterPlayerController?.betterPlayerAsmsTrack == t),
        )),
      ]
    );
    if (value != null) _betterPlayerController?.setTrack(value);
  }

  Future<void> _showAudioMenu() async {
    final tracks = _betterPlayerController?.betterPlayerAsmsAudioTracks ?? [];
    final value = await _showSubMenu<PlayerAsmsAudioTrack>(
      tracks.map((t) => PopupMenuItem<PlayerAsmsAudioTrack>(
        value: t,
        child: _buildCheckRow(t.label ?? 'Track ${t.id}', _betterPlayerController?.betterPlayerAsmsAudioTrack == t),
      )).toList()
    );
    if (value != null) _betterPlayerController?.setAudioTrack(value);
  }

  Future<void> _showSubtitlesMenu() async {
    final subs = _betterPlayerController?.betterPlayerSubtitlesSourceList ?? [];
    final value = await _showSubMenu<PlayerSubtitlesSource>(
      subs.map((s) => PopupMenuItem<PlayerSubtitlesSource>(
        value: s,
        child: _buildCheckRow(s.name ?? 'Unknown', _betterPlayerController?.betterPlayerSubtitlesSource == s),
      )).toList()
    );
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

  Widget _buildCheckRow(String title, bool isSelected) {
    return Row(
      children: [
        if (isSelected)
          Icon(Icons.check, color: widget.controlsConfiguration.iconsColor, size: 16)
        else
          const SizedBox(width: 16),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: widget.controlsConfiguration.textColor)),
      ],
    );
  }
}
