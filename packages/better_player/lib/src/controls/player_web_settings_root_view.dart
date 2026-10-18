import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/player_web_menu_row.dart';
import 'package:better_player/src/controls/player_web_settings_page.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/player_about_constants.dart';
import 'package:material_ui/material_ui.dart';

/// The root page for the web player settings menu.
class PlayerWebSettingsRootView extends StatelessWidget {
  /// Creates the root page displaying the settings categories.
  const PlayerWebSettingsRootView({
    required this.controller,
    required this.controlsConfiguration,
    required this.isAboutMenuVisible,
    required this.onNavigate,
    required this.onShowAbout,
    required this.onClose,
    super.key,
  });

  /// The player controller providing state and translations.
  final BetterPlayerController controller;

  /// Controls configuration containing UI options.
  final PlayerControlsConfiguration controlsConfiguration;

  /// Whether the About menu item should be shown.
  final bool isAboutMenuVisible;

  /// Callback to navigate to a subpage.
  final ValueChanged<PlayerWebSettingsPage> onNavigate;

  /// Callback to show the About dialog.
  final VoidCallback onShowAbout;

  /// Callback to close the menu.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controlsConfiguration.enableSubtitles)
            Semantics(
              label: 'better_player_overflow_menu_subtitles',
              identifier: 'better_player_overflow_menu_subtitles',
              button: true,
              child: InkWell(
                onTap: () => onNavigate(PlayerWebSettingsPage.subtitles),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: PlayerWebMenuRow(
                    title: controller.translations.overflowMenuSubtitles,
                    value:
                        controller.betterPlayerSubtitlesSource?.name ??
                        controller.translations.generalNone,
                    icon: Icons.subtitles,
                    controlsConfiguration: controlsConfiguration,
                  ),
                ),
              ),
            ),
          if (controlsConfiguration.enableQualities)
            Semantics(
              label: 'better_player_overflow_menu_quality',
              identifier: 'better_player_overflow_menu_quality',
              button: true,
              child: InkWell(
                onTap: () => onNavigate(PlayerWebSettingsPage.quality),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: PlayerWebMenuRow(
                    title: controller.translations.overflowMenuQuality,
                    value: _getResolutionLabel(),
                    icon: Icons.tune,
                    controlsConfiguration: controlsConfiguration,
                  ),
                ),
              ),
            ),
          if (controlsConfiguration.enableAudioTracks)
            Semantics(
              label: 'better_player_overflow_menu_audio_tracks',
              identifier: 'better_player_overflow_menu_audio_tracks',
              button: true,
              child: InkWell(
                onTap: () => onNavigate(PlayerWebSettingsPage.audioTracks),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: PlayerWebMenuRow(
                    title: controller.translations.overflowMenuAudioTracks,
                    value:
                        controller.betterPlayerAsmsAudioTrack?.label ??
                        controller.translations.generalDefault,
                    icon: Icons.language,
                    controlsConfiguration: controlsConfiguration,
                  ),
                ),
              ),
            ),
          if (controlsConfiguration.enablePlaybackSpeed)
            Semantics(
              label: 'better_player_overflow_menu_playback_speed',
              identifier: 'better_player_overflow_menu_playback_speed',
              button: true,
              child: InkWell(
                onTap: () => onNavigate(PlayerWebSettingsPage.playbackSpeed),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: PlayerWebMenuRow(
                    title: controller.translations.overflowMenuPlaybackSpeed,
                    value: '${controller.videoPlayerValue?.speed ?? 1.0}x',
                    icon: Icons.slow_motion_video,
                    controlsConfiguration: controlsConfiguration,
                  ),
                ),
              ),
            ),
          if (isAboutMenuVisible)
            Semantics(
              label: 'better_player_overflow_menu_about',
              identifier: 'better_player_overflow_menu_about',
              button: true,
              child: InkWell(
                onTap: () {
                  onClose();
                  onShowAbout();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: PlayerWebMenuRow(
                    title: controller.translations.overflowMenuAbout,
                    value: PlayerAboutConstants.version,
                    icon: Icons.info_outline,
                    controlsConfiguration: controlsConfiguration,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getResolutionLabel() {
    final asmsTrack = controller.betterPlayerAsmsTrack;
    if (asmsTrack != null) {
      if ((asmsTrack.width ?? 0) == 0 && (asmsTrack.height ?? 0) == 0) {
        return controller.translations.qualityAuto;
      }
      return '${asmsTrack.height}p';
    }
    final resolutions = controller.betterPlayerDataSource?.resolutions;
    if (resolutions != null && resolutions.isNotEmpty) {
      final currentUrl = controller.betterPlayerDataSource?.url;
      for (final entry in resolutions.entries) {
        if (entry.value == currentUrl) {
          return entry.key;
        }
      }
      return resolutions.keys.first;
    }
    return controller.translations.qualityAuto;
  }
}
