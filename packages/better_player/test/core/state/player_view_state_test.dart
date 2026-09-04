import 'package:better_player/src/core/state/player_view_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerViewState', () {
    test('should initialize with correct default values', () {
      final state = PlayerViewState();

      expect(state.isFullScreen, isFalse);
      expect(state.isPlayerVisible, isTrue);
      expect(state.controlsAlwaysVisible, isFalse);
      expect(state.controlsEnabled, isTrue);
      expect(state.wasInPipMode, isFalse);
      expect(state.wasInFullScreenBeforePiP, isFalse);
      expect(state.wasControlsEnabledBeforePiP, isFalse);
      expect(state.overriddenAspectRatio, isNull);
      expect(state.overriddenFit, isNull);
      expect(state.betterPlayerGlobalKey, isNull);
    });

    test('should allow updating fields', () {
      final state = PlayerViewState();
      final key = GlobalKey();

      state.isFullScreen = true;
      state.isPlayerVisible = false;
      state.overriddenFit = BoxFit.cover;
      state.betterPlayerGlobalKey = key;

      expect(state.isFullScreen, isTrue);
      expect(state.isPlayerVisible, isFalse);
      expect(state.overriddenFit, BoxFit.cover);
      expect(state.betterPlayerGlobalKey, key);
    });
  });
}
