class BetterPlayerPlaylistSettings {
  final Duration nextVideoDelay;
  final bool loopVideos;

  const BetterPlayerPlaylistSettings(
      {this.nextVideoDelay = const Duration(milliseconds: 3000),
      this.loopVideos = true});
}
