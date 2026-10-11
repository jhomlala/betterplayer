import 'package:better_player_example/model/example_item.dart';
import 'package:material_ui/material_ui.dart';

/// Clean, responsive card displaying a demo showcase entry.
class ExampleCard extends StatelessWidget {
  const ExampleCard({
    required this.item,
    super.key,
  });

  final ExampleItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSupported = item.isSupportedOnCurrentPlatform;
    final badgeText = item.badgeText ?? (!isSupported ? 'Unsupported' : null);
    final badgeColor = !isSupported
        ? (item.badgeColor ?? theme.colorScheme.error)
        : (item.badgeColor ?? theme.colorScheme.primary);

    return Semantics(
      identifier: item.identifier,
      container: true,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: !isSupported
                ? theme.colorScheme.error.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: item.pageBuilder),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: !isSupported
                      ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
                      : theme.colorScheme.primaryContainer,
                  foregroundColor: !isSupported
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                  child: Icon(item.icon, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? badgeColor.withValues(alpha: 0.2)
                                    : badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark
                                      ? badgeColor.withValues(alpha: 0.4)
                                      : badgeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
