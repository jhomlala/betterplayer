import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:open_iconic_flutter/open_iconic_flutter.dart';

class BetterPlayerControlsConfiguration {
  ///Color of the control bars
  final Color controlBarColor;

  ///Color of texts
  final Color textColor;

  ///Color of icons
  final Color iconsColor;

  ///Icon of play
  final IconData playIcon;

  ///Icon of pause
  final IconData pauseIcon;

  ///Icon of mute
  final IconData muteIcon;

  ///Icon of unmute
  final IconData unMuteIcon;

  ///Icon of fullscreen mode enable
  final IconData fullscreenEnableIcon;

  ///Icon of fullscreen mode disable
  final IconData fullscreenDisableIcon;

  ///Cupertino only icon, icon of skip
  final IconData skipBackIcon;

  ///Cupertino only icon, icon of forward
  final IconData skipForwardIcon;

  ///Flag used to enable/disable fullscreen
  final bool enableFullscreen;

  ///Flag used to enable/disable mute
  final bool enableMute;

  ///Flag used to enable/disable progress texts
  final bool enableProgressText;

  ///Flag used to enable/disable progress bar
  final bool enableProgressBar;

  ///Flag used to enable/disable play-pause
  final bool enablePlayPause;

  ///Progress bar played color
  final Color progressBarPlayedColor;

  ///Progress bar circle color
  final Color progressBarHandleColor;

  ///Progress bar buffered video color
  final Color progressBarBufferedColor;

  ///Progress bar background color
  final Color progressBarBackgroundColor;

  ///Time to hide controls
  final Duration controlsHideTime;

  ///Custom controls, it will override Material/Cupertino controls
  final Widget customControls;

  ///Flag used to show/hide controls
  final bool showControls;

  ///Flag used to show controls on init
  final bool showControlsOnInitialize;

  ///Control bar height
  final double controlBarHeight;

  ///Default error widget text
  final String defaultErrorText;

  ///Default loading next video text
  final String loadingNextVideoText;

  ///Text displayed when asset displayed in player is live stream
  final String liveText;

  ///Live text color;
  final Color liveTextColor;

  ///Flag used to show/hide playback speed
  final bool enablePlaybackSpeed;

  ///Flag used to show/hide subtitles
  final bool enableSubtitles;

  ///Flag used to show/hide tracks
  final bool enableTracks;

  const BetterPlayerControlsConfiguration({
    this.controlBarColor = Colors.black87,
    this.textColor = Colors.white,
    this.iconsColor = Colors.white,
    this.playIcon = Icons.play_arrow,
    this.pauseIcon = Icons.pause,
    this.muteIcon = Icons.volume_up,
    this.unMuteIcon = Icons.volume_mute,
    this.fullscreenEnableIcon = Icons.fullscreen,
    this.fullscreenDisableIcon = Icons.fullscreen_exit,
    this.skipBackIcon = OpenIconicIcons.reload,
    this.skipForwardIcon = OpenIconicIcons.reload,
    this.enableFullscreen = true,
    this.enableMute = true,
    this.enableProgressText = false,
    this.enableProgressBar = true,
    this.enablePlayPause = true,
    this.progressBarPlayedColor = Colors.white,
    this.progressBarHandleColor = Colors.white,
    this.progressBarBufferedColor = Colors.white70,
    this.progressBarBackgroundColor = Colors.white60,
    this.controlsHideTime = const Duration(milliseconds: 300),
    this.customControls,
    this.showControls = true,
    this.showControlsOnInitialize = true,
    this.controlBarHeight = 48.0,
    this.defaultErrorText = "Video can't be played",
    this.loadingNextVideoText = "Loading next video",
    this.liveText = "LIVE",
    this.liveTextColor = Colors.red,
    this.enablePlaybackSpeed = true,
    this.enableSubtitles = true,
    this.enableTracks = true,
  });

  factory BetterPlayerControlsConfiguration.white() {
    return BetterPlayerControlsConfiguration(
        controlBarColor: Colors.white,
        textColor: Colors.black,
        iconsColor: Colors.black,
        progressBarPlayedColor: Colors.black,
        progressBarHandleColor: Colors.black,
        progressBarBufferedColor: Colors.black54,
        progressBarBackgroundColor: Colors.white70);
  }

  factory BetterPlayerControlsConfiguration.cupertino() {
    return BetterPlayerControlsConfiguration(
        fullscreenEnableIcon: OpenIconicIcons.fullscreenEnter,
        fullscreenDisableIcon: OpenIconicIcons.fullscreenExit,
        playIcon: OpenIconicIcons.mediaPlay,
        pauseIcon: OpenIconicIcons.mediaPause,
        enableProgressText: true);
  }
}
