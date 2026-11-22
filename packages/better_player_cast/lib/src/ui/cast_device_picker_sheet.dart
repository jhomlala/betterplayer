import 'package:better_player_cast/src/config/cast_configuration.dart';
import 'package:better_player_cast/src/models/cast_device.dart';
import 'package:better_player_cast/src/ui/cast_connected_banner.dart';
import 'package:better_player_cast/src/ui/cast_device_tile.dart';
import 'package:better_player_cast/src/ui/cast_empty_state.dart';
import 'package:material_ui/material_ui.dart';

/// Modal bottom sheet displaying available Cast devices and disconnect control.
class CastDevicePickerSheet extends StatelessWidget {
  /// Creates a Cast device picker modal bottom sheet.
  const CastDevicePickerSheet({
    required this.configuration,
    required this.devices,
    required this.isScanning,
    required this.onDeviceSelected,
    required this.onDisconnect,
    this.connectedDevice,
    super.key,
  });

  /// Cast configuration.
  final CastConfiguration configuration;

  /// List of discovered Cast devices.
  final List<CastDevice> devices;

  /// Whether device discovery is actively scanning.
  final bool isScanning;

  /// Currently connected device if any.
  final CastDevice? connectedDevice;

  /// Callback when a user taps a device tile.
  final ValueChanged<CastDevice> onDeviceSelected;

  /// Callback when a user requests to disconnect from active receiver.
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      identifier: 'better_player_cast_picker_sheet',
      container: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        configuration.pickerTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Semantics(
                      identifier: 'better_player_cast_close_button',
                      button: true,
                      label: 'Close',
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (connectedDevice != null)
                CastConnectedBanner(
                  device: connectedDevice!,
                  onDisconnect: onDisconnect,
                  disconnectLabel: configuration.disconnectText,
                ),
              if (devices.isEmpty)
                CastEmptyState(
                  isScanning: isScanning,
                  scanningText: configuration.scanningText,
                  noDevicesText: configuration.noDevicesText,
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return CastDeviceTile(
                        device: device,
                        isSelected: device.id == connectedDevice?.id,
                        onTap: () => onDeviceSelected(device),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
