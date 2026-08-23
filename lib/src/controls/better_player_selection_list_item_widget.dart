import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerSelectionListItemWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final String? semanticsIdentifier;

  const BetterPlayerSelectionListItemWidget({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.controlsConfiguration,
    this.semanticsIdentifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BetterPlayerMaterialClickableWidget(
      onTap: onTap,
      semanticsLabel: label,
      semanticsIdentifier: semanticsIdentifier,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
              visible: isSelected,
              child: Icon(
                Icons.check_outlined,
                color: controlsConfiguration.overflowModalTextColor,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: _getTextStyle(),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getTextStyle() {
    return TextStyle(
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      color: isSelected
          ? controlsConfiguration.overflowModalTextColor
          : controlsConfiguration.overflowModalTextColor.withValues(
              alpha: 0.7,
            ),
    );
  }
}
