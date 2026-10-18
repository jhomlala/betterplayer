import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/player_web_settings_audio_view.dart';
import 'package:better_player/src/controls/player_web_settings_page.dart';
import 'package:better_player/src/controls/player_web_settings_quality_view.dart';
import 'package:better_player/src/controls/player_web_settings_root_view.dart';
import 'package:better_player/src/controls/player_web_settings_speed_view.dart';
import 'package:better_player/src/controls/player_web_settings_subtitles_view.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

/// In-place drill-down settings menu overlay for web and desktop controls.
class PlayerWebSettingsMenu extends StatefulWidget {
  /// Creates the settings menu with root and drill-down category pages.
  const PlayerWebSettingsMenu({
    required this.controller,
    required this.controlsConfiguration,
    required this.isAboutMenuVisible,
    required this.onClose,
    required this.onShowAbout,
    super.key,
  });

  /// The player controller providing state and commands.
  final BetterPlayerController controller;

  /// Controls configuration containing UI settings and colors.
  final PlayerControlsConfiguration controlsConfiguration;

  /// Whether the About menu item should be shown.
  final bool isAboutMenuVisible;

  /// Callback invoked when an option is selected or menu is dismissed.
  final VoidCallback onClose;

  /// Callback invoked when the user selects the About item.
  final VoidCallback onShowAbout;

  @override
  State<PlayerWebSettingsMenu> createState() => _PlayerWebSettingsMenuState();
}

class _PlayerWebSettingsMenuState extends State<PlayerWebSettingsMenu> {
  PlayerWebSettingsPage _currentPage = PlayerWebSettingsPage.root;

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_currentPage) {
      case PlayerWebSettingsPage.root:
        content = PlayerWebSettingsRootView(
          controller: widget.controller,
          controlsConfiguration: widget.controlsConfiguration,
          isAboutMenuVisible: widget.isAboutMenuVisible,
          onNavigate: (page) => setState(() => _currentPage = page),
          onShowAbout: widget.onShowAbout,
          onClose: widget.onClose,
        );
      case PlayerWebSettingsPage.quality:
        content = PlayerWebSettingsQualityView(
          controller: widget.controller,
          controlsConfiguration: widget.controlsConfiguration,
          onBack: () =>
              setState(() => _currentPage = PlayerWebSettingsPage.root),
          onClose: widget.onClose,
        );
      case PlayerWebSettingsPage.playbackSpeed:
        content = PlayerWebSettingsSpeedView(
          controller: widget.controller,
          controlsConfiguration: widget.controlsConfiguration,
          onBack: () =>
              setState(() => _currentPage = PlayerWebSettingsPage.root),
          onClose: widget.onClose,
        );
      case PlayerWebSettingsPage.audioTracks:
        content = PlayerWebSettingsAudioView(
          controller: widget.controller,
          controlsConfiguration: widget.controlsConfiguration,
          onBack: () =>
              setState(() => _currentPage = PlayerWebSettingsPage.root),
          onClose: widget.onClose,
        );
      case PlayerWebSettingsPage.subtitles:
        content = PlayerWebSettingsSubtitlesView(
          controller: widget.controller,
          controlsConfiguration: widget.controlsConfiguration,
          onBack: () =>
              setState(() => _currentPage = PlayerWebSettingsPage.root),
          onClose: widget.onClose,
        );
    }

    return Semantics(
      label: 'better_player_web_settings_menu',
      identifier: 'better_player_web_settings_menu',
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 240,
          maxWidth: 400,
          maxHeight: 420,
        ),
        child: Material(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(8),
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          child: IntrinsicWidth(
            child: content,
          ),
        ),
      ),
    );
  }
}
