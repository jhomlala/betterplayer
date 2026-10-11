import 'package:material_ui/material_ui.dart';

/// Card informing users about platform-specific compatibility, restrictions, or requirements.
class PlatformNoteCard extends StatelessWidget {
  const PlatformNoteCard({
    required this.message,
    super.key,
    this.title = 'Platform Note',
    this.icon = Icons.info_outline,
    this.isWarning = false,
  });

  /// Card heading.
  final String title;

  /// Compatibility explanation.
  final String message;

  /// Leading icon.
  final IconData icon;

  /// Whether to highlight as a warning or restriction.
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isWarning
        ? (isDark
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
              : theme.colorScheme.errorContainer.withValues(alpha: 0.5))
        : (isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ));

    final borderColor = isWarning
        ? theme.colorScheme.error.withValues(alpha: 0.4)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    final iconColor = isWarning
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isWarning
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
