import 'package:better_player/src/video_player/video_player.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoHitArea extends StatelessWidget {
  const BetterPlayerCupertinoHitArea({
    required this.latestValue,
    required this.controlsNotVisible,
    required this.onCancelAndRestartTimer,
    required this.onHideTimerCancel,
    required this.onChangePlayerControlsNotVisible,
    super.key,
  });
  final VideoPlayerValue? latestValue;
  final bool controlsNotVisible;
  final VoidCallback onCancelAndRestartTimer;
  final VoidCallback onHideTimerCancel;
  final Function(bool) onChangePlayerControlsNotVisible;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: latestValue != null && latestValue!.isPlaying
            ? () {
                if (controlsNotVisible) {
                  onCancelAndRestartTimer();
                } else {
                  onHideTimerCancel();
                  onChangePlayerControlsNotVisible(true);
                }
              }
            : () {
                onHideTimerCancel();
                onChangePlayerControlsNotVisible(false);
              },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
}
