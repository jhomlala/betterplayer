import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerOverflowMenu extends StatelessWidget {
  const BetterPlayerOverflowMenu({
    required this.controller,
    required this.controlsConfiguration,
    required this.onPlaybackSpeedClicked,
    required this.onSubtitlesClicked,
    required this.onQualitiesClicked,
    required this.onAudioTracksClicked,
    super.key,
  });
  final BetterPlayerController controller;
  final PlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onPlaybackSpeedClicked;
  final VoidCallback onSubtitlesClicked;
  final VoidCallback onQualitiesClicked;
  final VoidCallback onAudioTracksClicked;

  @override
  Widget build(BuildContext context) {
    final translations = controller.translations;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (controlsConfiguration.enablePlaybackSpeed)
            PlayerOverflowMenuItemWidget(
              icon: controlsConfiguration.playbackSpeedIcon,
              name: translations.overflowMenuPlaybackSpeed,
              onTap: onPlaybackSpeedClicked,
              controlsConfiguration: controlsConfiguration,
              semanticsIdentifier: 'better_player_overflow_menu_playback_speed',
            ),
          if (controlsConfiguration.enableSubtitles)
            PlayerOverflowMenuItemWidget(
              key: const Key('better_player_overflow_menu_subtitles'),
              icon: controlsConfiguration.subtitlesIcon,
              name: translations.overflowMenuSubtitles,
              onTap: onSubtitlesClicked,
              controlsConfiguration: controlsConfiguration,
              semanticsIdentifier: 'better_player_overflow_menu_subtitles',
            ),
          if (controlsConfiguration.enableQualities)
            PlayerOverflowMenuItemWidget(
              key: const Key('better_player_overflow_menu_qualities'),
              icon: controlsConfiguration.qualitiesIcon,
              name: translations.overflowMenuQuality,
              onTap: onQualitiesClicked,
              controlsConfiguration: controlsConfiguration,
              semanticsIdentifier: 'better_player_overflow_menu_quality',
            ),
          if (controlsConfiguration.enableAudioTracks)
            PlayerOverflowMenuItemWidget(
              key: const Key('better_player_overflow_menu_audio_tracks'),
              icon: controlsConfiguration.audioTracksIcon,
              name: translations.overflowMenuAudioTracks,
              onTap: onAudioTracksClicked,
              controlsConfiguration: controlsConfiguration,
              semanticsIdentifier: 'better_player_overflow_menu_audio_tracks',
            ),
          if (controlsConfiguration.overflowMenuCustomItems.isNotEmpty)
            ...controlsConfiguration.overflowMenuCustomItems.map(
              (customItem) => PlayerOverflowMenuItemWidget(
                icon: customItem.icon,
                name: customItem.title,
                onTap: () {
                  Navigator.of(context).pop();
                  customItem.onClicked.call();
                },
                controlsConfiguration: controlsConfiguration,
                semanticsIdentifier:
                    'better_player_overflow_menu_custom_item_${customItem.title.toLowerCase().replaceAll(' ', '_')}',
              ),
            ),
        ],
      ),
    );
  }
}

class PlayerOverflowMenuItemWidget extends StatelessWidget {
  const PlayerOverflowMenuItemWidget({
    required this.icon,
    required this.name,
    required this.onTap,
    required this.controlsConfiguration,
    this.isSelected = false,
    this.semanticsIdentifier,
    super.key,
  });
  final IconData icon;
  final String name;
  final VoidCallback onTap;
  final PlayerControlsConfiguration controlsConfiguration;
  final bool isSelected;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    PlayerLogger.debug(
      'E2E: Building PlayerOverflowMenuItemWidget: $name (ID: $semanticsIdentifier)',
    );
    return BetterPlayerMaterialClickableWidget(
      onTap: onTap,
      semanticsLabel: name,
      semanticsIdentifier: semanticsIdentifier,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(icon, color: controlsConfiguration.overflowMenuIconsColor),
            const SizedBox(width: 16),
            Text(name, style: _getOverflowMenuElementTextStyle(isSelected)),
          ],
        ),
      ),
    );
  }

  TextStyle _getOverflowMenuElementTextStyle(bool isSelected) {
    return TextStyle(
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      color: isSelected
          ? controlsConfiguration.overflowModalTextColor
          : controlsConfiguration.overflowModalTextColor.withValues(alpha: 0.7),
    );
  }
}
