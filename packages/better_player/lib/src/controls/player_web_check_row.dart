import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:material_ui/material_ui.dart';

/// A selectable row in a web settings submenu.
class PlayerWebCheckRow extends StatelessWidget {
  /// Creates a selectable row showing an active checkmark when selected.
  const PlayerWebCheckRow({
    required this.title,
    required this.isSelected,
    required this.controlsConfiguration,
    super.key,
  });

  /// The option display label.
  final String title;

  /// Whether this option is currently selected.
  final bool isSelected;

  /// Controls configuration containing colors and styles.
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isSelected)
          Icon(
            Icons.check,
            color: controlsConfiguration.iconsColor,
            size: 16,
          )
        else
          const SizedBox(width: 16),
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
      ],
    );
  }
}
