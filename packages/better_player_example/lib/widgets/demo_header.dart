import 'package:material_ui/material_ui.dart';

/// Clean, lightweight information header at the top of demo pages.
/// Displays the title, description, and optional test instructions.
class DemoHeader extends StatelessWidget {
  const DemoHeader({
    required this.title,
    required this.description,
    super.key,
    this.instructions,
    this.icon = Icons.info_outline,
  });

  /// Short headline of the feature or screen.
  final String title;

  /// Plain explanation of what the example demonstrates.
  final String description;

  /// Optional specific steps or tips on how to interact with the demo.
  final String? instructions;

  /// Leading icon representing the topic.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (instructions != null) ...[
            const SizedBox(height: 6),
            Text(
              instructions!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
