import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/player_web_check_row.dart';
import 'package:better_player/src/controls/player_web_settings_header.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

/// The playback speed selection page for web player settings.
class PlayerWebSettingsSpeedView extends StatelessWidget {
  /// Creates a speed selection view showing configured playback rates.
  const PlayerWebSettingsSpeedView({
    required this.controller,
    required this.controlsConfiguration,
    required this.onBack,
    required this.onClose,
    super.key,
  });

  /// The player controller providing speed state and methods.
  final BetterPlayerController controller;

  /// Controls configuration containing configured playback speeds.
  final PlayerControlsConfiguration controlsConfiguration;

  /// Callback to return to the root settings page.
  final VoidCallback onBack;

  /// Callback to close the settings menu.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final speeds = controlsConfiguration.playbackSpeeds;
    final currentSpeed = controller.videoPlayerValue?.speed ?? 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerWebSettingsHeader(
          title: controller.translations.overflowMenuPlaybackSpeed,
          onBack: onBack,
          controlsConfiguration: controlsConfiguration,
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: speeds.map((s) {
                final speedStr = s == s.roundToDouble()
                    ? s.toStringAsFixed(1)
                    : '$s';
                final identifier =
                    'better_player_overflow_menu_speed_$speedStr';
                return Semantics(
                  label: identifier,
                  identifier: identifier,
                  button: true,
                  child: InkWell(
                    onTap: () {
                      controller.setSpeed(s);
                      onClose();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: PlayerWebCheckRow(
                        title: '${s}x',
                        isSelected: currentSpeed == s,
                        controlsConfiguration: controlsConfiguration,
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
