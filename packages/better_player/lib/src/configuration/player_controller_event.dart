///Internal events of BetterPlayerController, used in widgets to update state.
enum PlayerControllerEvent {
  ///Fullscreen mode has started.
  openFullscreen,

  ///Fullscreen mode has ended.
  hideFullscreen,

  ///Subtitles changed.
  changeSubtitles,

  ///New data source has been set.
  setupDataSource,

  //Video has started.
  play,

  ///Controls configuration has been updated.
  changeControlsConfiguration,

  ///Subtitles configuration has been updated.
  changeSubtitlesConfiguration,
}
