import 'package:better_player/src/asms/player_asms_track.dart';
import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/player_web_check_row.dart';
import 'package:better_player/src/controls/player_web_settings_header.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

/// The quality and resolution selection page for web player settings.
class PlayerWebSettingsQualityView extends StatelessWidget {
  /// Creates a resolution selection view with available tracks or source resolutions.
  const PlayerWebSettingsQualityView({
    required this.controller,
    required this.controlsConfiguration,
    required this.onBack,
    required this.onClose,
    super.key,
  });

  /// The player controller providing tracks and resolution methods.
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
      title: controller.translations.overflowMenuQuality,
      onBack: onBack,
      controlsConfiguration: controlsConfiguration,
    );

    final resolutions = controller.betterPlayerDataSource?.resolutions;
    if (resolutions != null && resolutions.isNotEmpty) {
      final currentUrl = controller.betterPlayerDataSource?.url;
      var resolutionIndex = 0;
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
                children: resolutions.entries.map((entry) {
                  final isSelected = entry.value == currentUrl;
                  final identifier =
                      'better_player_overflow_menu_quality_$resolutionIndex';
                  resolutionIndex++;
                  return Semantics(
                    label: identifier,
                    identifier: identifier,
                    container: true,
                    button: true,
                    child: InkWell(
                      onTap: () {
                        controller.setResolution(entry.value);
                        onClose();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: PlayerWebCheckRow(
                          title: entry.key,
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

    final tracks = controller.betterPlayerAsmsTracks;
    if (tracks.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Semantics(
            label: 'better_player_overflow_menu_quality_auto',
            identifier: 'better_player_overflow_menu_quality_auto',
            container: true,
            button: true,
            child: InkWell(
              onTap: () {
                controller.setTrack(PlayerAsmsTrack.defaultTrack());
                onClose();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: PlayerWebCheckRow(
                  title: controller.translations.qualityAuto,
                  isSelected: true,
                  controlsConfiguration: controlsConfiguration,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final trackWidgets = <Widget>[];
    for (var index = 0; index < tracks.length; index++) {
      final t = tracks[index];
      final isAuto = (t.width ?? 0) == 0 && (t.height ?? 0) == 0;
      final label = isAuto
          ? controller.translations.qualityAuto
          : '${t.height}p';
      final isSelected = controller.betterPlayerAsmsTrack == t;
      final identifier = isAuto
          ? 'better_player_overflow_menu_quality_auto'
          : 'better_player_overflow_menu_quality_$index';

      trackWidgets.add(
        Semantics(
          label: identifier,
          identifier: identifier,
          container: true,
          button: true,
          child: InkWell(
            onTap: () {
              controller.setTrack(t);
              onClose();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: PlayerWebCheckRow(
                title: label,
                isSelected: isSelected,
                controlsConfiguration: controlsConfiguration,
              ),
            ),
          ),
        ),
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
              children: trackWidgets,
            ),
          ),
        ),
      ],
    );
  }
}
