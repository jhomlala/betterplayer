import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_overflow_menu.dart';
import 'package:better_player/src/controls/better_player_selection_list_item_widget.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

///Base class for both material and cupertino controls
abstract class BetterPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
  ///Min. time of buffered video to hide loading timer (in milliseconds)
  static const int _bufferingInterval = 20000;

  BetterPlayerController? get betterPlayerController;

  PlayerControlsConfiguration get betterPlayerControlsConfiguration;

  VideoPlayerValue? get latestValue;

  bool controlsNotVisible = true;

  void cancelAndRestartTimer();

  bool isVideoFinished(VideoPlayerValue? videoPlayerValue) {
    if (videoPlayerValue == null) return false;
    final position = videoPlayerValue.position;
    final duration = videoPlayerValue.duration;
    if (duration == null) return false;
    return position.inMilliseconds != 0 &&
        duration.inMilliseconds != 0 &&
        position >= duration;
  }

  void skipBack() {
    if (latestValue != null) {
      cancelAndRestartTimer();
      final beginning = const Duration().inMilliseconds;
      final skip =
          (latestValue!.position -
                  Duration(
                    milliseconds: betterPlayerControlsConfiguration
                        .backwardSkipTimeInMilliseconds,
                  ))
              .inMilliseconds;
      betterPlayerController!.seekTo(
        Duration(milliseconds: max(skip, beginning)),
      );
    }
  }

  void skipForward() {
    if (latestValue != null) {
      cancelAndRestartTimer();
      final end = latestValue!.duration!.inMilliseconds;
      final skip =
          (latestValue!.position +
                  Duration(
                    milliseconds: betterPlayerControlsConfiguration
                        .forwardSkipTimeInMilliseconds,
                  ))
              .inMilliseconds;
      betterPlayerController!.seekTo(Duration(milliseconds: min(skip, end)));
    }
  }

  void onShowMoreClicked() {
    PlayerLogger.debug(message: 'onShowMoreClicked');
    final translations = betterPlayerController!.translations;
    final children = <Widget>[];

    if (betterPlayerControlsConfiguration.enablePlaybackSpeed) {
      children.add(_buildBottomSheetMenuItem(
        icon: betterPlayerControlsConfiguration.playbackSpeedIcon,
        label: translations.overflowMenuPlaybackSpeed,
        onTap: () {
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 500),
            _showSpeedChooserWidget,
          );
        },
        semanticsIdentifier: 'better_player_overflow_menu_playback_speed',
      ));
    }

    if (betterPlayerControlsConfiguration.enableSubtitles) {
      children.add(_buildBottomSheetMenuItem(
        icon: betterPlayerControlsConfiguration.subtitlesIcon,
        label: translations.overflowMenuSubtitles,
        onTap: () {
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 500),
            _showSubtitlesSelectionWidget,
          );
        },
        semanticsIdentifier: 'better_player_overflow_menu_subtitles',
      ));
    }

    if (betterPlayerControlsConfiguration.enableQualities) {
      children.add(_buildBottomSheetMenuItem(
        icon: betterPlayerControlsConfiguration.qualitiesIcon,
        label: translations.overflowMenuQuality,
        onTap: () {
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 500),
            showQualitiesSelectionWidget,
          );
        },
        semanticsIdentifier: 'better_player_overflow_menu_quality',
      ));
    }

    if (betterPlayerControlsConfiguration.enableAudioTracks) {
      children.add(_buildBottomSheetMenuItem(
        icon: betterPlayerControlsConfiguration.audioTracksIcon,
        label: translations.overflowMenuAudioTracks,
        onTap: () {
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 300),
            _showAudioTracksSelectionWidget,
          );
        },
        semanticsIdentifier: 'better_player_overflow_menu_audio_tracks',
      ));
    }

    if (betterPlayerControlsConfiguration.overflowMenuCustomItems.isNotEmpty) {
      for (final customItem
          in betterPlayerControlsConfiguration.overflowMenuCustomItems) {
        children.add(_buildBottomSheetMenuItem(
          icon: customItem.icon,
          label: customItem.title,
          onTap: () {
            Navigator.of(context).pop();
            customItem.onClicked.call();
          },
          semanticsIdentifier:
              'better_player_overflow_menu_custom_item_${customItem.title.toLowerCase().replaceAll(' ', '_')}',
        ));
      }
    }

    _showModalBottomSheet(children);
  }

  void _showSpeedChooserWidget() {
    _showModalBottomSheet(
      [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
        final isSelected =
            betterPlayerController?.videoPlayerValue?.speed == speed;
        return _buildBottomSheetMenuItem(
          label: '$speed x',
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setSpeed(speed);
          },
          semanticsIdentifier: 'better_player_overflow_menu_speed_$speed',
        );
      }).toList(),
    );
  }

  ///Latest value can be null
  bool isLoading(VideoPlayerValue? latestValue) {
    if (latestValue != null) {
      if (!latestValue.isPlaying && latestValue.duration == null) {
        return true;
      }

      final position = latestValue.position;

      Duration? bufferedEndPosition;
      if (latestValue.buffered.isNotEmpty) {
        bufferedEndPosition = latestValue.buffered.last.end;
      }

      if (bufferedEndPosition != null) {
        final difference = bufferedEndPosition - position;

        if (latestValue.isPlaying &&
            latestValue.isBuffering &&
            difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  void _showSubtitlesSelectionWidget() {
    final subtitles = List.of(
      betterPlayerController!.betterPlayerSubtitlesSourceList,
    );
    final noneSubtitlesElementExists =
        subtitles.firstWhereOrNull(
          (source) => source.type == PlayerSubtitlesSourceType.none,
        ) !=
        null;
    if (!noneSubtitlesElementExists) {
      subtitles.add(
        PlayerSubtitlesSource(type: PlayerSubtitlesSourceType.none),
      );
    }

    _showModalBottomSheet(
      subtitles.map((subtitlesSource) {
        final selectedSourceType =
            betterPlayerController!.betterPlayerSubtitlesSource;
        final isSelected =
            (subtitlesSource == selectedSourceType) ||
            (subtitlesSource.type == PlayerSubtitlesSourceType.none &&
                subtitlesSource.type == selectedSourceType!.type);

        final name = subtitlesSource.type == PlayerSubtitlesSourceType.none
            ? betterPlayerController!.translations.generalNone
            : subtitlesSource.name ??
                  betterPlayerController!.translations.generalDefault;

        return _buildBottomSheetMenuItem(
          label: name,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setupSubtitleSource(subtitlesSource);
          },
          semanticsIdentifier:
              'better_player_overflow_menu_subtitles_${subtitlesSource.type?.name ?? 'none'}',
        );
      }).toList(),
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS / DASH videos
  ///Resolution selection is used for normal videos
  void showQualitiesSelectionWidget() {
    PlayerLogger.debug(message: 'showQualitiesSelectionWidget started');
    // HLS / DASH
    final asmsTrackNames =
        betterPlayerController!.betterPlayerDataSource!.asmsTrackNames ?? [];
    final asmsTracks = betterPlayerController!.betterPlayerAsmsTracks;
    PlayerLogger.debug(message: 'ASMS Tracks: ${asmsTracks.length}');
    final children = <Widget>[];
    for (var index = 0; index < asmsTracks.length; index++) {
      final track = asmsTracks[index];

      String? preferredName;
      if ((track.width ?? 0) == 0 &&
          (track.height ?? 0) == 0 &&
          (track.bitrate ?? 0) == 0) {
        preferredName = betterPlayerController!.translations.qualityAuto;
      } else {
        preferredName = asmsTrackNames.length > index
            ? asmsTrackNames[index]
            : null;
      }

      final width = track.width ?? 0;
      final height = track.height ?? 0;
      final bitrate = track.bitrate ?? 0;
      final mimeType = (track.mimeType ?? '').replaceAll('video/', '');
      final trackName =
          preferredName ??
          '${width}x$height ${BetterPlayerUiUtils.formatBitrate(bitrate)} $mimeType';

      final selectedTrack = betterPlayerController!.betterPlayerAsmsTrack;
      final isSelected = selectedTrack != null && selectedTrack == track;
      final isAutoTrack =
          preferredName == betterPlayerController!.translations.qualityAuto;

      children.add(
        _buildBottomSheetMenuItem(
          label: trackName,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setTrack(track);
          },
          semanticsIdentifier: isAutoTrack
              ? 'better_player_overflow_menu_quality_auto'
              : 'better_player_overflow_menu_quality_$index',
        ),
      );
    }

    // normal videos
    final resolutions =
        betterPlayerController!.betterPlayerDataSource!.resolutions;
    PlayerLogger.debug(message: 'Resolutions: ${resolutions?.length ?? 0}');
    var resolutionIndex = 0;
    resolutions?.forEach((key, value) {
      final isSelected =
          value == betterPlayerController!.betterPlayerDataSource!.url;
      children.add(
        _buildBottomSheetMenuItem(
          label: key,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setResolution(value);
          },
          semanticsIdentifier:
              'better_player_overflow_menu_quality_$resolutionIndex',
        ),
      );
      resolutionIndex++;
    });

    if (children.isEmpty) {
      PlayerLogger.debug(
        message: 'Quality children empty, adding Auto fallback',
      );
      children.add(
        _buildBottomSheetMenuItem(
          label: betterPlayerController!.translations.qualityAuto,
          isSelected: true,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setTrack(PlayerAsmsTrack.defaultTrack());
          },
          semanticsIdentifier: 'better_player_overflow_menu_quality_auto',
        ),
      );
    }

    PlayerLogger.debug(
      message: 'Showing qualities menu with ${children.length} items',
    );
    _showModalBottomSheet(children);
  }

  void _showAudioTracksSelectionWidget() {
    //HLS / DASH
    final asmsTracks = betterPlayerController!.betterPlayerAsmsAudioTracks;
    final children = <Widget>[];
    final selectedAsmsAudioTrack =
        betterPlayerController!.betterPlayerAsmsAudioTrack;
    if (asmsTracks.isNotEmpty) {
      for (var index = 0; index < asmsTracks.length; index++) {
        final isSelected =
            selectedAsmsAudioTrack != null &&
            selectedAsmsAudioTrack == asmsTracks[index];
        final audioTrack = asmsTracks[index];
        children.add(
          _buildBottomSheetMenuItem(
            label: audioTrack.label ?? '',
            isSelected: isSelected,
            onTap: () {
              Navigator.of(context).pop();
              betterPlayerController!.setAudioTrack(audioTrack);
            },
          ),
        );
      }
    }

    if (children.isEmpty) {
      children.add(
        _buildBottomSheetMenuItem(
          label: betterPlayerController!.translations.generalDefault,
          isSelected: true,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setAudioTrack(
              PlayerAsmsAudioTrack(
                label: betterPlayerController!.translations.generalDefault,
              ),
            );
          },
        ),
      );
    }

    _showModalBottomSheet(children);
  }

  void _showModalBottomSheet(List<Widget> children) {
    PlayerLogger.debug(
      message: 'Showing bottom sheet with ${children.length} items',
    );
    !_isCupertinoTheme ? _showMaterialBottomSheet(children) : _showCupertinoModalBottomSheet(children);
  }


  bool get _isCupertinoTheme {
    return betterPlayerControlsConfiguration.playerTheme == PlayerTheme.cupertino || (betterPlayerControlsConfiguration.playerTheme == null && defaultTargetPlatform == TargetPlatform.iOS);
  }

  Widget _buildBottomSheetMenuItem({
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
    IconData? icon,
    String? semanticsIdentifier,
  }) {
    if (_isCupertinoTheme) {
      return CupertinoActionSheetAction(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 20),
            if (icon != null) const SizedBox(width: 8),
            if (isSelected && icon == null) const Icon(Icons.check, size: 18),
            if (isSelected && icon == null) const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
    }
    
    if (icon != null) {
      return PlayerOverflowMenuItemWidget(
        icon: icon,
        name: label,
        onTap: onTap,
        controlsConfiguration: betterPlayerControlsConfiguration,
        semanticsIdentifier: semanticsIdentifier,
      );
    } else {
      return BetterPlayerSelectionListItemWidget(
        label: label,
        isSelected: isSelected,
        onTap: onTap,
        controlsConfiguration: betterPlayerControlsConfiguration,
        semanticsIdentifier: semanticsIdentifier,
      );
    }
  }

  void _showCupertinoModalBottomSheet(List<Widget> children) {
    showCupertinoModalPopup<void>(
      barrierColor: Colors.transparent,
      context: context,
      useRootNavigator:
          betterPlayerController?.betterPlayerConfiguration.useRootNavigator ??
          false,
      builder: (context) {
        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Theme.of(context).brightness,
          ),
          child: CupertinoActionSheet(
            actions: children,
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
          ),
        );
      },
    );
  }

  void _showMaterialBottomSheet(List<Widget> children) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      useRootNavigator:
          betterPlayerController?.betterPlayerConfiguration.useRootNavigator ??
          false,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: betterPlayerControlsConfiguration.overflowModalColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(children: children),
            ),
          ),
        );
      },
    );
  }

  ///Called when player controls visibility should be changed.
  void changePlayerControlsNotVisible(bool notVisible) {
    setState(() {
      if (notVisible) {
        betterPlayerController?.postEvent(
          PlayerEvent(PlayerEventType.controlsHiddenStart),
        );
      }
      controlsNotVisible = notVisible;
    });
  }
}


