import 'package:better_player/src/engine/player_engine_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

final BetterPlayerPlatform _betterPlayerPlatform =
    BetterPlayerPlatform.instance;

/// Widget that displays the video controlled by [controller].
class VideoPlayer extends StatefulWidget {
  /// Uses the given [controller] for all video rendered in this widget.
  const VideoPlayer(this.controller, {super.key});

  /// The [PlayerEngineController] responsible for the video being rendered in
  /// this widget.
  final PlayerEngineController? controller;

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  _VideoPlayerState() {
    _listener = () {
      final newTextureId = widget.controller!.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  late VoidCallback _listener;
  int? _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller!.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller!.addListener(_listener);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller!.removeListener(_listener);
    _textureId = widget.controller!.textureId;
    widget.controller!.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller!.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == null
        ? Container()
        : _betterPlayerPlatform.buildView(_textureId);
  }
}

/// Used to configure the [VideoProgressIndicator] widget's colors for how it
