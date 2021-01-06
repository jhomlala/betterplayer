class BetterPlayerPlaylistConfiguration {
  ///How long user should wait for next video
  final Duration nextVideoDelay;

  ///Should videos be looped
  final bool loopVideos;

  BetterPlayerPlaylistConfiguration(
      {this.nextVideoDelay = const Duration(milliseconds: 3000),
      this.loopVideos = true})
      : assert(nextVideoDelay != null && nextVideoDelay.inSeconds >= 3,
            "NextVideoDelay should be at least 3 seconds");
}
