import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

class BetterPlayerListVideoPlayer extends StatefulWidget {
  final BetterPlayerDataSource dataSource;
  final BetterPlayerSettings settings;
  final double playFraction;
  final bool autoPlay;
  final bool autoPause;

  const BetterPlayerListVideoPlayer(this.dataSource,
      {this.settings = const BetterPlayerSettings(),
      this.playFraction = 0.6,
      this.autoPlay = true,
      this.autoPause = true,
      Key key})
      : assert(dataSource != null, "Data source can't be null"),
        assert(settings != null, "Settings can't be null"),
        assert(
            playFraction != null && playFraction >= 0.0 && playFraction <= 1.0,
            "Play fraction can't be null and must be between 0.0 and 1.0"),
        assert(autoPlay != null, "Auto play can't be null"),
        assert(autoPause != null, "Auto pause can't be null"),
        super(key: key);

  @override
  _BetterPlayerListVideoPlayerState createState() =>
      _BetterPlayerListVideoPlayerState();
}

class _BetterPlayerListVideoPlayerState
    extends State<BetterPlayerListVideoPlayer>
    with AutomaticKeepAliveClientMixin<BetterPlayerListVideoPlayer> {
  BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    _betterPlayerController = BetterPlayerController(
      widget.settings,
      betterPlayerDataSource: widget.dataSource,
    );
    super.initState();
  }

  @override
  void dispose() {
    print("DISPOSE VIDEOO!!");
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      child: BetterPlayer(
        key: Key(widget.dataSource.hashCode.toString() + "_player"),
        controller: _betterPlayerController,
        betterPlayerDataSource: widget.dataSource,
      ),
      onVisibilityChanged: (visibilityInfo) async {
        bool isPlaying = await _betterPlayerController.isPlaying();
        bool initialized = _betterPlayerController.isVideoInitialized();
        if (visibilityInfo.visibleFraction >= widget.playFraction) {
          if (widget.autoPlay && initialized && !isPlaying) {
            _betterPlayerController.play();
          }
        } else {
          if (widget.autoPause && initialized && isPlaying) {
            _betterPlayerController.pause();
          }
        }
      },
      key: Key(widget.dataSource.hashCode.toString()),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
