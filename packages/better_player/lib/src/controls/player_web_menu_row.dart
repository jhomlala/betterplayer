import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:material_ui/material_ui.dart';

/// A navigation row in the root web player settings menu.
class PlayerWebMenuRow extends StatelessWidget {
  /// Creates a navigation row with a title, leading icon, and trailing chevron.
  const PlayerWebMenuRow({
    required this.title,
    required this.icon,
    required this.controlsConfiguration,
    this.value,
    this.showChevron = true,
    super.key,
  });

  /// The category title text.
  final String title;

  /// Optional current value text displayed on the right.
  final String? value;

  /// The leading icon for this menu item.
  final IconData icon;

  /// Controls configuration containing colors and styles.
  final PlayerControlsConfiguration controlsConfiguration;

  /// Whether the trailing chevron icon is shown.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final valueText = value;
    return Row(
      children: [
        Icon(
          icon,
          color: controlsConfiguration.iconsColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: controlsConfiguration.textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        const SizedBox(width: 24),
        if (valueText != null && valueText.isNotEmpty) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              valueText,
              style: TextStyle(
                color: controlsConfiguration.textColor,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (showChevron)
          Icon(
            Icons.chevron_right,
            color: controlsConfiguration.iconsColor,
            size: 16,
          ),
      ],
    );
  }
}
