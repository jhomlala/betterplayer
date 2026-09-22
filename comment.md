Custom controls let you place the exact buttons you need wherever you want them. Set `PlayerTheme.custom` and pass your own widget to `customControlsBuilder`. Better Player passes the controller, you wire up the UI.

Here's how to configure the player:

`dart
final configuration = PlayerConfiguration(
  controlsConfiguration: PlayerControlsConfiguration(
    playerTheme: PlayerTheme.custom,
    customControlsBuilder: (controller, onControlsVisibilityChanged) {
      return MyCustomControls(controller: controller);
    },
  ),
);
`

And here is a working overlay with the exit button and skip/rewind actions:

`dart
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';

class MyCustomControls extends StatelessWidget {
  final BetterPlayerController controller;

  const MyCustomControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () => controller.enterFullScreen(),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => controller.exitFullScreen(),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.fast_rewind, color: Colors.white),
                onPressed: () {
                  final position = controller.videoPlayerValue?.position ?? Duration.zero;
                  controller.seekTo(position - const Duration(seconds: 10));
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () {
                  if (controller.isPlaying() == true) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.fast_forward, color: Colors.white),
                onPressed: () {
                  final position = controller.videoPlayerValue?.position ?? Duration.zero;
                  controller.seekTo(position + const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
`

Check out [custom_controls_widget.dart](https://github.com/jhomlala/betterplayer/blob/master/example/lib/pages/custom_controls/custom_controls_widget.dart) in the repository for a complete implementation (yes, it already exists).
