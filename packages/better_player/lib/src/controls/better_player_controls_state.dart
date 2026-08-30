import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_overflow_menu.dart';
import 'package:better_player/src/controls/better_player_selection_list_item_widget.dart';
import 'package:better_player/src/core/better_player_logger.dart';
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
    return videoPlayerValue?.position != null &&
        videoPlayerValue?.duration != null &&
        videoPlayerValue!.position.inMilliseconds != 0 &&
        videoPlayerValue.duration!.inMilliseconds != 0 &&
        videoPlayerValue.position >= videoPlayerValue.duration!;
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
    Logger.debug(
      'onShowMoreClicked',
      breadcrumb: 'Controls',
    );
    _showModalBottomSheet([
      BetterPlayerOverflowMenu(
        controller: betterPlayerController!,
        controlsConfiguration: betterPlayerControlsConfiguration,
        onPlaybackSpeedClicked: () {
          Logger.debug(
            'onPlaybackSpeedClicked',
            breadcrumb: 'Controls',
          );
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 500),
            _showSpeedChooserWidget,
          );
        },
        onSubtitlesClicked: () {
          Logger.debug(
            'onSubtitlesClicked',
            breadcrumb: 'Controls',
          );
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 500),
            _showSubtitlesSelectionWidget,
          );
        },
        onQualitiesClicked: () {
          Logger.debug(
            'onQualitiesClicked',
            breadcrumb: 'Controls',
          );
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 500),
            showQualitiesSelectionWidget,
          );
        },
        onAudioTracksClicked: () {
          Logger.debug(
            'onAudioTracksClicked',
            breadcrumb: 'Controls',
          );
          Navigator.of(context).pop();
          Future.delayed(
            const Duration(milliseconds: 300),
            _showAudioTracksSelectionWidget,
          );
        },
      ),
    ]);
  }

  void _showSpeedChooserWidget() {
    _showModalBottomSheet(
      [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
        final isSelected =
            betterPlayerController!.videoPlayerController!.value.speed == speed;
        return BetterPlayerSelectionListItemWidget(
          label: '$speed x',
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setSpeed(speed);
          },
          controlsConfiguration: betterPlayerControlsConfiguration,
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
        PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.none,
        ),
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

        return BetterPlayerSelectionListItemWidget(
          label: name,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setupSubtitleSource(subtitlesSource);
          },
          controlsConfiguration: betterPlayerControlsConfiguration,
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
    Logger.debug(
      'showQualitiesSelectionWidget started',
      breadcrumb: 'Controls',
    );
    // HLS / DASH
    final asmsTrackNames =
        betterPlayerController!.betterPlayerDataSource!.asmsTrackNames ?? [];
    final asmsTracks = betterPlayerController!.betterPlayerAsmsTracks;
    Logger.debug(
      'ASMS Tracks: ${asmsTracks.length}',
      breadcrumb: 'Controls',
    );
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
        BetterPlayerSelectionListItemWidget(
          label: trackName,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setTrack(track);
          },
          controlsConfiguration: betterPlayerControlsConfiguration,
          semanticsIdentifier: isAutoTrack
              ? 'better_player_overflow_menu_quality_auto'
              : 'better_player_overflow_menu_quality_$index',
        ),
      );
    }

    // normal videos
    final resolutions =
        betterPlayerController!.betterPlayerDataSource!.resolutions;
    Logger.debug(
      'Resolutions: ${resolutions?.length ?? 0}',
      breadcrumb: 'Controls',
    );
    var resolutionIndex = 0;
    resolutions?.forEach((key, value) {
      final isSelected =
          value == betterPlayerController!.betterPlayerDataSource!.url;
      children.add(
        BetterPlayerSelectionListItemWidget(
          label: key,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setResolution(value);
          },
          controlsConfiguration: betterPlayerControlsConfiguration,
          semanticsIdentifier:
              'better_player_overflow_menu_quality_$resolutionIndex',
        ),
      );
      resolutionIndex++;
    });

    if (children.isEmpty) {
      Logger.debug(
        'Quality children empty, adding Auto fallback',
        breadcrumb: 'Controls',
      );
      children.add(
        BetterPlayerSelectionListItemWidget(
          label: betterPlayerController!.translations.qualityAuto,
          isSelected: true,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setTrack(
              PlayerAsmsTrack.defaultTrack(),
            );
          },
          controlsConfiguration: betterPlayerControlsConfiguration,
          semanticsIdentifier: 'better_player_overflow_menu_quality_auto',
        ),
      );
    }

    Logger.debug(
      'Showing qualities menu with ${children.length} items',
      breadcrumb: 'Controls',
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
          BetterPlayerSelectionListItemWidget(
            label: audioTrack.label!,
            isSelected: isSelected,
            onTap: () {
              Navigator.of(context).pop();
              betterPlayerController!.setAudioTrack(audioTrack);
            },
            controlsConfiguration: betterPlayerControlsConfiguration,
          ),
        );
      }
    }

    if (children.isEmpty) {
      children.add(
        BetterPlayerSelectionListItemWidget(
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
          controlsConfiguration: betterPlayerControlsConfiguration,
        ),
      );
    }

    _showModalBottomSheet(children);
  }

  void _showModalBottomSheet(List<Widget> children) {
    Logger.debug(
      'Showing bottom sheet with ${children.length} items',
      breadcrumb: 'Controls',
    );
    defaultTargetPlatform == TargetPlatform.android
        ? _showMaterialBottomSheet(children)
        : _showCupertinoModalBottomSheet(children);
  }

  void _showCupertinoModalBottomSheet(List<Widget> children) {
    showCupertinoModalPopup<void>(
      barrierColor: Colors.transparent,
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
                /*shape: RoundedRectangleBorder(side: Bor,borderRadius: 24,)*/
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: children,
              ),
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
              child: Column(
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  ///Builds directionality widget which wraps child widget and forces left to
  ///right directionality.
  Widget buildLTRDirectionality(Widget child) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
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
