import 'package:better_player/src/controls/better_player_overflow_menu_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('BetterPlayerOverflowMenuItem model test', () {
    var clicked = false;
    final item = BetterPlayerOverflowMenuItem(
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
