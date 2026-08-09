import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BetterPlayerProgressColors test', () {
    final colors = BetterPlayerProgressColors(
      playedColor: const Color(0xFF000001),
      bufferedColor: const Color(0xFF000002),
      handleColor: const Color(0xFF000003),
      backgroundColor: const Color(0xFF000004),
    );

    expect(colors.playedPaint.color.value, const Color(0xFF000001).value);
    expect(colors.bufferedPaint.color.value, const Color(0xFF000002).value);
    expect(colors.handlePaint.color.value, const Color(0xFF000003).value);
    expect(colors.backgroundPaint.color.value, const Color(0xFF000004).value);
  });
}
