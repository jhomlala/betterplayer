import 'package:better_player/src/controls/player_progress_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('PlayerProgressColors test', () {
    final colors = PlayerProgressColors(
      playedColor: const Color(0xFF000001),
      bufferedColor: const Color(0xFF000002),
      handleColor: const Color(0xFF000003),
      backgroundColor: const Color(0xFF000004),
    );

    expect(colors.playedPaint.color.toARGB32(), 0xFF000001);
    expect(colors.bufferedPaint.color.toARGB32(), 0xFF000002);
    expect(colors.handlePaint.color.toARGB32(), 0xFF000003);
    expect(colors.backgroundPaint.color.toARGB32(), 0xFF000004);
  });
}
