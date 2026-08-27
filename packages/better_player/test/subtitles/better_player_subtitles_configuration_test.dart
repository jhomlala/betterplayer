import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('PlayerSubtitlesConfiguration default values', () {
    const config = PlayerSubtitlesConfiguration();
    expect(config.fontSize, 14);
    expect(config.fontColor, Colors.white);
    expect(config.outlineEnabled, true);
    expect(config.alignment, Alignment.center);
  });

  test('PlayerSubtitlesConfiguration custom values', () {
    const config = PlayerSubtitlesConfiguration(
      fontSize: 20,
      fontColor: Colors.red,
      alignment: Alignment.bottomLeft,
    );
    expect(config.fontSize, 20);
    expect(config.fontColor, Colors.red);
    expect(config.alignment, Alignment.bottomLeft);
  });
}
