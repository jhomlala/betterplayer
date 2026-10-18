import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/player_web_check_row.dart';
import 'package:better_player/src/controls/player_web_settings_header.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

/// The audio track selection page for web player settings.
class PlayerWebSettingsAudioView extends StatelessWidget {
  /// Creates an audio track selection view.
  const PlayerWebSettingsAudioView({
    required this.controller,
    required this.controlsConfiguration,
    required this.onBack,
    required this.onClose,
    super.key,
  });

  /// The player controller providing audio tracks and selection methods.
  final BetterPlayerController controller;

  /// Controls configuration containing UI options.
  final PlayerControlsConfiguration controlsConfiguration;

  /// Callback to return to the root settings page.
  final VoidCallback onBack;

  /// Callback to close the settings menu.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final header = PlayerWebSettingsHeader(
      title: controller.translations.overflowMenuAudioTracks,
      onBack: onBack,
      controlsConfiguration: controlsConfiguration,
    );

    final tracks = controller.betterPlayerAsmsAudioTracks;
    if (tracks.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Semantics(
            label: 'better_player_overflow_menu_audio_tracks_default',
            identifier: 'better_player_overflow_menu_audio_tracks_default',
            container: true,
            child: Semantics(
              container: true,
              button: true,
              child: InkWell(
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: PlayerWebCheckRow(
                    title: controller.translations.generalDefault,
                    isSelected: true,
                    controlsConfiguration: controlsConfiguration,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: tracks.map((t) {
                return Semantics(
                  label:
                      'better_player_overflow_menu_audio_tracks_${t.id ?? 'unknown'}',
                  identifier:
                      'better_player_overflow_menu_audio_tracks_${t.id ?? 'unknown'}',
                  container: true,
                  child: Semantics(
                    container: true,
                    button: true,
                    child: InkWell(
                      onTap: () {
                        controller.setAudioTrack(t);
                        onClose();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: PlayerWebCheckRow(
                          title: t.label ?? 'Track ${t.id}',
                          isSelected:
                              controller.betterPlayerAsmsAudioTrack == t,
                          controlsConfiguration: controlsConfiguration,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
