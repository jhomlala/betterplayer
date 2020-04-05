class BetterPlayerPlaylistConfiguration {
  final Duration nextVideoDelay;
  final bool loopVideos;

  const BetterPlayerPlaylistConfiguration(
      {this.nextVideoDelay = const Duration(milliseconds: 3000),
      this.loopVideos = true});
}
