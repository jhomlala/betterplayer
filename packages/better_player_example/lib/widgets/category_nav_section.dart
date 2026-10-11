import 'package:better_player_example/widgets/category_nav_card.dart';
import 'package:material_ui/material_ui.dart';

/// Navigation section presenting cards for each demo showcase category.
class CategoryNavSection extends StatelessWidget {
  const CategoryNavSection({
    required this.isWideScreen,
    required this.onNavigateToTab,
    required this.coreItemsCount,
    required this.streamingItemsCount,
    required this.advancedItemsCount,
    super.key,
  });

  final bool isWideScreen;
  final void Function(int index) onNavigateToTab;
  final int coreItemsCount;
  final int streamingItemsCount;
  final int advancedItemsCount;

  @override
  Widget build(BuildContext context) {
    final categories = [
      (
        title: 'Core & UI',
        subtitle:
            '$coreItemsCount demos: default player, custom themes, and controls',
        icon: Icons.play_circle_outline,
        tabIndex: 1,
      ),
      (
        title: 'Streaming & Protocols',
        subtitle:
            '$streamingItemsCount demos: HLS, DASH, DRM, bitrates, and subtitles',
        icon: Icons.stream_outlined,
        tabIndex: 2,
      ),
      (
        title: 'Advanced & Feeds',
        subtitle:
            '$advancedItemsCount demos: feeds, caching, PiP, notifications, and FFI',
        icon: Icons.tune_outlined,
        tabIndex: 3,
      ),
    ];

    if (isWideScreen) {
      return Row(
        children: categories.map((cat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: CategoryNavCard(
                title: cat.title,
                subtitle: cat.subtitle,
                icon: cat.icon,
                onTap: () => onNavigateToTab(cat.tabIndex),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: categories.map((cat) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CategoryNavCard(
            title: cat.title,
            subtitle: cat.subtitle,
            icon: cat.icon,
            onTap: () => onNavigateToTab(cat.tabIndex),
          ),
        );
      }).toList(),
    );
  }
}
