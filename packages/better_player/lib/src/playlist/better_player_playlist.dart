import 'package:better_player/better_player.dart';

// Flutter imports:
import 'package:material_ui/material_ui.dart';

///Special version of Better Player used to play videos in playlist.
class BetterPlayerPlaylist extends StatefulWidget {
  final List<BetterPlayerDataSource> betterPlayerDataSourceList;
  final BetterPlayerConfiguration betterPlayerConfiguration;
  final BetterPlayerPlaylistConfiguration betterPlayerPlaylistConfiguration;

  const BetterPlayerPlaylist({
    required this.betterPlayerDataSourceList,
    required this.betterPlayerConfiguration,
    required this.betterPlayerPlaylistConfiguration,
    super.key,
  });

  @override
  BetterPlayerPlaylistState createState() => BetterPlayerPlaylistState();
}

///State of BetterPlayerPlaylist, used to access BetterPlayerPlaylistController.
class BetterPlayerPlaylistState extends State<BetterPlayerPlaylist> {
  BetterPlayerPlaylistController? _betterPlayerPlaylistController;

  BetterPlayerController? get _betterPlayerController =>
      _betterPlayerPlaylistController!.betterPlayerController;

  ///Get BetterPlayerPlaylistController
  BetterPlayerPlaylistController? get betterPlayerPlaylistController =>
      _betterPlayerPlaylistController;

  @override
  void initState() {
    _betterPlayerPlaylistController = BetterPlayerPlaylistController(
      widget.betterPlayerDataSourceList,
      betterPlayerConfiguration: widget.betterPlayerConfiguration,
      betterPlayerPlaylistConfiguration:
          widget.betterPlayerPlaylistConfiguration,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio:
          _betterPlayerController!.getAspectRatio() ??
          BetterPlayerUiUtils.calculateAspectRatio(context),
      child: BetterPlayer(
        controller: _betterPlayerController!,
      ),
    );
  }

  @override
  void dispose() {
    _betterPlayerPlaylistController!.dispose();
    super.dispose();
  }
}
