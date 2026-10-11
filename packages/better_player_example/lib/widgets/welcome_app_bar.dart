import 'package:better_player_example/main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Top app bar for the Better Player example showcase.
class WelcomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WelcomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final currentMode = BetterPlayerExample.themeModeOf(context);

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/logo.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 10),
          const Text(
            'Better Player',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<ThemeMode>(
          tooltip: 'Select theme mode',
          icon: Icon(
            switch (currentMode) {
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
              ThemeMode.system => Icons.brightness_auto,
            },
          ),
          initialValue: currentMode,
          onSelected: (mode) => BetterPlayerExample.setThemeMode(context, mode),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(Icons.brightness_auto, size: 20),
                  SizedBox(width: 10),
                  Text('System'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(Icons.light_mode, size: 20),
                  SizedBox(width: 10),
                  Text('Light'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(Icons.dark_mode, size: 20),
                  SizedBox(width: 10),
                  Text('Dark'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
