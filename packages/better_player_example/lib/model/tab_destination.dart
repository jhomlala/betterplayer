import 'package:material_ui/material_ui.dart';

/// Navigation destination data for WelcomePage shell.
class TabDestination {
  const TabDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
