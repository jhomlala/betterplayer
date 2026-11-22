import 'package:better_player_cast/src/models/cast_device.dart';
import 'package:material_ui/material_ui.dart';

/// Interactive list tile representing a discovered Cast device in the picker sheet.
class CastDeviceTile extends StatelessWidget {
  /// Creates a device list tile.
  const CastDeviceTile({
    required this.device,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  /// Target Cast device.
  final CastDevice device;

  /// Callback when this device is tapped.
  final VoidCallback onTap;

  /// Whether this device is the currently connected device.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'better_player_cast_device_item_${device.id}',
      button: true,
      label: device.name,
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.cast_connected : Icons.tv,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: device.modelName != null ? Text(device.modelName!) : null,
        trailing: isSelected
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
