import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:material_ui/material_ui.dart';

/// Navigation header for web player settings submenus.
class PlayerWebSettingsHeader extends StatelessWidget {
  /// Creates a header with a back button, title, and bottom divider.
  const PlayerWebSettingsHeader({
    required this.title,
    required this.onBack,
    required this.controlsConfiguration,
    super.key,
  });

  /// Category title displayed in the header.
  final String title;

  /// Callback invoked when the user taps the back button.
  final VoidCallback onBack;

  /// Controls configuration containing colors and styles.
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'better_player_overflow_menu_back',
          identifier: 'better_player_overflow_menu_back',
          button: true,
          onTap: onBack,
          excludeSemantics: true,
          child: InkWell(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back,
                    color: controlsConfiguration.iconsColor,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: controlsConfiguration.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.white24),
      ],
    );
  }
}
