import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

class BetterPlayerListVideoPlayer extends StatefulWidget {
  ///Video to show
  final BetterPlayerDataSource dataSource;

  ///Video player settings
  final BetterPlayerSettings settings;

  ///Fraction of the screen height that will trigger play/pause. For example
  ///if playFraction is 0.6 video will be played if 60% of player height is
  ///visible.
  final double playFraction;

  ///Flag to determine if video should be auto played
  final bool autoPlay;

  ///Flag to determine if video should be auto paused
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
  bool _isDisposing = false;

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
    _isDisposing = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      child: BetterPlayer(
        key: Key(widget.dataSource.hashCode.toString() + "_player"),
        controller: _betterPlayerController,
      ),
      onVisibilityChanged: (visibilityInfo) async {
        bool isPlaying = await _betterPlayerController.isPlaying();
        bool initialized = _betterPlayerController.isVideoInitialized();
        if (visibilityInfo.visibleFraction >= widget.playFraction) {
          if (widget.autoPlay && initialized && !isPlaying && !_isDisposing) {
            _betterPlayerController.play();
          }
        } else {
          if (widget.autoPause && initialized && isPlaying && !_isDisposing) {
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
