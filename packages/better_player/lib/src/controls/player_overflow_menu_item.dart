// Flutter imports:
import 'package:material_ui/material_ui.dart';

///Menu item data used in overflow menu (3 dots).
class PlayerOverflowMenuItem {
  PlayerOverflowMenuItem(this.icon, this.title, this.onClicked);

  ///Icon of menu item
  final IconData icon;

  ///Title of menu item
  final String title;

  ///Callback when item is clicked
  final Function() onClicked;
}
