import 'package:better_player_example/model/example_item.dart';
import 'package:better_player_example/widgets/category_nav_card.dart';
import 'package:better_player_example/widgets/example_card.dart';
import 'package:better_player_example/widgets/hero_banner.dart';
import 'package:material_ui/material_ui.dart';

/// Screen presenting the high-level showcase overview and featured entries.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    required this.isWideScreen,
    required this.onNavigateToTab,
    required this.featuredItems,
    super.key,
  });

  final bool isWideScreen;
  final void Function(int index) onNavigateToTab;
  final List<ExampleItem> featuredItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeroBanner(),
          const SizedBox(height: 24),
          Text(
            'Explore Categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryNavigationCards(),
          const SizedBox(height: 24),
          Text(
            'Featured Showcases',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeaturedGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryNavigationCards() {
    final categories = [
      (
        title: 'Core & UI',
        subtitle: '8 demos: default player, custom themes, and controls',
        icon: Icons.play_circle_outline,
        tabIndex: 1,
      ),
      (
        title: 'Streaming & Protocols',
        subtitle: '9 demos: HLS, DASH, DRM, bitrates, and subtitles',
        icon: Icons.stream_outlined,
        tabIndex: 2,
      ),
      (
        title: 'Advanced & Feeds',
        subtitle: '13 demos: feeds, caching, PiP, notifications, and FFI',
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

  Widget _buildFeaturedGrid() {
    if (isWideScreen) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 108,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: featuredItems.length,
        itemBuilder: (context, index) =>
            ExampleCard(item: featuredItems[index]),
      );
    }

    return Column(
      children: featuredItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExampleCard(item: item),
            ),
          )
          .toList(),
    );
  }
}
