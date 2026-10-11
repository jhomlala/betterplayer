import 'package:better_player_example/model/example_item.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/example_card.dart';
import 'package:material_ui/material_ui.dart';

/// Screen presenting all demo showcases for a single category.
class CategoryTab extends StatelessWidget {
  const CategoryTab({
    required this.title,
    required this.description,
    required this.items,
    required this.isWideScreen,
    super.key,
  });

  final String title;
  final String description;
  final List<ExampleItem> items;
  final bool isWideScreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: DemoContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (isWideScreen)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 80,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    ExampleCard(item: items[index]),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    ExampleCard(item: items[index]),
              ),
          ],
        ),
      ),
    );
  }
}
