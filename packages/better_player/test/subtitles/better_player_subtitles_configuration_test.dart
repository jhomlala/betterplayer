import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('BetterPlayerSubtitlesConfiguration default values', () {
    const config = BetterPlayerSubtitlesConfiguration();
    expect(config.fontSize, 14);
    expect(config.fontColor, Colors.white);
    expect(config.outlineEnabled, true);
    expect(config.alignment, Alignment.center);
  });

  test('BetterPlayerSubtitlesConfiguration custom values', () {
    const config = BetterPlayerSubtitlesConfiguration(
      fontSize: 20,
      fontColor: Colors.red,
      alignment: Alignment.bottomLeft,
    );
    expect(config.fontSize, 20);
    expect(config.fontColor, Colors.red);
    expect(config.alignment, Alignment.bottomLeft);
  });
}
