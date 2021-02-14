///Additional configuration used in Better Player Playlist player.
class BetterPlayerPlaylistConfiguration {
  ///How long user should wait for next video
  final Duration nextVideoDelay;

  ///Should videos be looped
  final bool loopVideos;

  const BetterPlayerPlaylistConfiguration({
    this.nextVideoDelay = const Duration(milliseconds: 3000),
    this.loopVideos = true,
  })  : assert(nextVideoDelay != null),
        assert(loopVideos != null);
}
