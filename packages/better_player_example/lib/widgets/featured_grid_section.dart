import 'package:better_player_example/model/example_item.dart';
import 'package:better_player_example/widgets/example_card.dart';
import 'package:material_ui/material_ui.dart';

/// Section presenting featured showcase demos in a responsive grid or column.
class FeaturedGridSection extends StatelessWidget {
  const FeaturedGridSection({
    required this.isWideScreen,
    required this.featuredItems,
    super.key,
  });

  final bool isWideScreen;
  final List<ExampleItem> featuredItems;

  @override
  Widget build(BuildContext context) {
    if (isWideScreen) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 80,
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
