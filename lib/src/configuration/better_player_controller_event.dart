///Internal events of BetterPlayerController, used in widgets to update state.
enum BetterPlayerControllerEvent {
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

  //Show play next video
  showPlayNextVideo,

  //Hide play next video
  hidePlayNextVideo,

  //Show skip intro button
  showSkipIntro,

  //Hide skip intro button
  hideSkipIntro
}
