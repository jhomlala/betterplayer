import 'dart:io';
import 'dart:math';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_overflow_menu.dart';
import 'package:better_player/src/controls/better_player_selection_list_item_widget.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

///Base class for both material and cupertino controls
abstract class BetterPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
  ///Min. time of buffered video to hide loading timer (in milliseconds)
  static const int _bufferingInterval = 20000;

  BetterPlayerController? get betterPlayerController;

  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration;

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
    _showModalBottomSheet([
      BetterPlayerOverflowMenu(
        controller: betterPlayerController!,
        controlsConfiguration: betterPlayerControlsConfiguration,
        onPlaybackSpeedClicked: () {
          Navigator.of(context).pop();
          _showSpeedChooserWidget();
        },
        onSubtitlesClicked: () {
          Navigator.of(context).pop();
          _showSubtitlesSelectionWidget();
        },
        onQualitiesClicked: () {
          Navigator.of(context).pop();
          _showQualitiesSelectionWidget();
        },
        onAudioTracksClicked: () {
          Navigator.of(context).pop();
          _showAudioTracksSelectionWidget();
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
      if (latestValue.buffered.isNotEmpty == true) {
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
          (source) => source.type == BetterPlayerSubtitlesSourceType.none,
        ) !=
        null;
    if (!noneSubtitlesElementExists) {
      subtitles.add(
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.none,
        ),
      );
    }

    _showModalBottomSheet(
      subtitles.map((subtitlesSource) {
        final selectedSourceType =
            betterPlayerController!.betterPlayerSubtitlesSource;
        final isSelected =
            (subtitlesSource == selectedSourceType) ||
            (subtitlesSource.type == BetterPlayerSubtitlesSourceType.none &&
                subtitlesSource.type == selectedSourceType!.type);

        final name =
            subtitlesSource.type == BetterPlayerSubtitlesSourceType.none
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
              'better_player_overflow_menu_subtitles_${subtitlesSource.type.name}',
        );
      }).toList(),
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS / DASH videos
  ///Resolution selection is used for normal videos
  void _showQualitiesSelectionWidget() {
    // HLS / DASH
    final asmsTrackNames =
        betterPlayerController!.betterPlayerDataSource!.asmsTrackNames ?? [];
    final asmsTracks = betterPlayerController!.betterPlayerAsmsTracks;
    final children = <Widget>[];
    for (var index = 0; index < asmsTracks.length; index++) {
      final track = asmsTracks[index];

      String? preferredName;
      if (track.height == 0 && track.width == 0 && track.bitrate == 0) {
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
          '${width}x$height ${BetterPlayerUtils.formatBitrate(bitrate)} $mimeType';

      final selectedTrack = betterPlayerController!.betterPlayerAsmsTrack;
      final isSelected = selectedTrack != null && selectedTrack == track;

      children.add(
        BetterPlayerSelectionListItemWidget(
          label: trackName,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setTrack(track);
          },
          controlsConfiguration: betterPlayerControlsConfiguration,
          semanticsIdentifier: 'better_player_overflow_menu_quality_$index',
        ),
      );
    }

    // normal videos
    final resolutions =
        betterPlayerController!.betterPlayerDataSource!.resolutions;
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
        ),
      );
    });

    if (children.isEmpty) {
      children.add(
        BetterPlayerSelectionListItemWidget(
          label: betterPlayerController!.translations.qualityAuto,
          isSelected: true,
          onTap: () {
            Navigator.of(context).pop();
            betterPlayerController!.setTrack(
              BetterPlayerAsmsTrack.defaultTrack(),
            );
          },
          controlsConfiguration: betterPlayerControlsConfiguration,
          semanticsIdentifier: 'better_player_overflow_menu_quality_auto',
        ),
      );
    }

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
              BetterPlayerAsmsAudioTrack(
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
    Platform.isAndroid
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
          BetterPlayerEvent(BetterPlayerEventType.controlsHiddenStart),
        );
      }
      controlsNotVisible = notVisible;
    });
  }
}
