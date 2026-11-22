/// Playback state of the remote Cast media player.
enum CastPlayerState {
  /// Player is idle, stopped, or no media is loaded.
  idle,

  /// Media is actively playing.
  playing,

  /// Media is paused.
  paused,

  /// Media is buffering data.
  buffering,

  /// Media is loading.
  loading,
}
