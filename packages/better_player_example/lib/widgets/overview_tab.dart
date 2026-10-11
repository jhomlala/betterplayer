import 'package:better_player_example/model/example_item.dart';
import 'package:better_player_example/widgets/category_nav_section.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/featured_grid_section.dart';
import 'package:better_player_example/widgets/overview_hero_player.dart';
import 'package:material_ui/material_ui.dart';

/// Screen presenting the high-level showcase overview, live player, and featured entries.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    required this.isWideScreen,
    required this.onNavigateToTab,
    required this.featuredItems,
    required this.coreItemsCount,
    required this.streamingItemsCount,
    required this.advancedItemsCount,
    super.key,
  });

  final bool isWideScreen;
  final void Function(int index) onNavigateToTab;
  final List<ExampleItem> featuredItems;
  final int coreItemsCount;
  final int streamingItemsCount;
  final int advancedItemsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: DemoContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OverviewHeroPlayer(),
            const SizedBox(height: 24),
            Text(
              'Explore Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CategoryNavSection(
              isWideScreen: isWideScreen,
              onNavigateToTab: onNavigateToTab,
              coreItemsCount: coreItemsCount,
              streamingItemsCount: streamingItemsCount,
              advancedItemsCount: advancedItemsCount,
            ),
            const SizedBox(height: 24),
            Text(
              'Featured Showcases',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            FeaturedGridSection(
              isWideScreen: isWideScreen,
              featuredItems: featuredItems,
            ),
          ],
        ),
      ),
    );
  }
}
