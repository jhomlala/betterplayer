import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/player_web_check_row.dart';
import 'package:better_player/src/controls/player_web_settings_header.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/subtitles/player_subtitles_source.dart';
import 'package:better_player/src/subtitles/player_subtitles_source_type.dart';
import 'package:material_ui/material_ui.dart';

/// The subtitles selection page for web player settings.
class PlayerWebSettingsSubtitlesView extends StatelessWidget {
  /// Creates a subtitles selection view.
  const PlayerWebSettingsSubtitlesView({
    required this.controller,
    required this.controlsConfiguration,
    required this.onBack,
    required this.onClose,
    super.key,
  });

  /// The player controller providing subtitles sources.
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
      title: controller.translations.overflowMenuSubtitles,
      onBack: onBack,
      controlsConfiguration: controlsConfiguration,
    );

    final subtitles = List.of(controller.betterPlayerSubtitlesSourceList);
    final hasNone = subtitles.any(
      (source) => source.type == PlayerSubtitlesSourceType.none,
    );
    if (!hasNone) {
      subtitles.add(
        PlayerSubtitlesSource(type: PlayerSubtitlesSourceType.none),
      );
    }

    final selectedSource = controller.betterPlayerSubtitlesSource;

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
              children: subtitles.map((s) {
                final isSelected =
                    (s == selectedSource) ||
                    (s.type == PlayerSubtitlesSourceType.none &&
                        (selectedSource == null ||
                            selectedSource.type ==
                                PlayerSubtitlesSourceType.none));

                final name = s.type == PlayerSubtitlesSourceType.none
                    ? controller.translations.generalNone
                    : s.name ?? controller.translations.generalDefault;

                final identifier =
                    'better_player_overflow_menu_subtitles_${s.type?.name ?? 'none'}';

                return Semantics(
                  label: identifier,
                  identifier: identifier,
                  container: true,
                  button: true,
                  child: InkWell(
                    onTap: () {
                      controller.setupSubtitleSource(s);
                      onClose();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: PlayerWebCheckRow(
                        title: name,
                        isSelected: isSelected,
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
