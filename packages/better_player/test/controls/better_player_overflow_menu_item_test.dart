import 'package:better_player/src/controls/player_overflow_menu_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('PlayerOverflowMenuItem model test', () {
    var clicked = false;
    final item = PlayerOverflowMenuItem(
      Icons.settings,
      'Settings',
      () => clicked = true,
    );

    expect(item.icon, Icons.settings);
    expect(item.title, 'Settings');
    item.onClicked();
    expect(clicked, true);
  });
}
