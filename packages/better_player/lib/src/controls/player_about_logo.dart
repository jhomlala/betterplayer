import 'package:better_player/src/core/player_about_constants.dart';
import 'package:material_ui/material_ui.dart';

/// Better Player logo loaded from GitHub. Shows an icon when loading fails.
class PlayerAboutLogo extends StatelessWidget {
  const PlayerAboutLogo({super.key});

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      PlayerAboutConstants.logoUrl,
      width: _size,
      height: _size,
      cacheWidth: 192,
      fit: BoxFit.contain,
      semanticLabel: PlayerAboutConstants.poweredBy,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(width: _size, height: _size);
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.play_circle_outline, size: _size);
      },
    );
  }
}
