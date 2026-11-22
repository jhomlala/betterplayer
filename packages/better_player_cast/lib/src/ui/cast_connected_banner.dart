import 'package:better_player_cast/src/models/cast_device.dart';
import 'package:material_ui/material_ui.dart';

/// Banner shown when casting is active on a remote device.
class CastConnectedBanner extends StatelessWidget {
  /// Creates a Cast connected banner.
  const CastConnectedBanner({
    required this.device,
    required this.onDisconnect,
    required this.disconnectLabel,
    super.key,
  });

  /// Currently connected device.
  final CastDevice device;

  /// Callback when disconnect is pressed.
  final VoidCallback onDisconnect;

  /// Disconnect button text.
  final String disconnectLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      identifier: 'better_player_cast_connected_banner',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cast_connected,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Casting to',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    device.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Semantics(
              identifier: 'better_player_cast_disconnect_button',
              button: true,
              label: disconnectLabel,
              child: TextButton(
                onPressed: onDisconnect,
                child: Text(disconnectLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
