import 'package:material_ui/material_ui.dart';

/// Empty or scanning state widget inside the Cast device picker sheet.
class CastEmptyState extends StatelessWidget {
  /// Creates a Cast empty state widget.
  const CastEmptyState({
    required this.isScanning,
    required this.scanningText,
    required this.noDevicesText,
    super.key,
  });

  /// Whether discovery is actively scanning for devices.
  final bool isScanning;

  /// Text shown while discovery is scanning.
  final String scanningText;

  /// Text shown when no devices have been found.
  final String noDevicesText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'better_player_cast_empty_state',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isScanning) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 16),
                Text(
                  scanningText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.cast,
                  size: 36,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  noDevicesText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
