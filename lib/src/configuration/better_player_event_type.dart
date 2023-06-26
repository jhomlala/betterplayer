///Supported event types
enum BetterPlayerEventType {
  initialized,
  play,
  pause,
  seekTo,
  openFullscreen,
  hideFullscreen,
  setVolume,
  progress,
  finished,
  exception,
  controlsVisible,
  controlsHiddenStart,
  controlsHiddenEnd,
  setSpeed,
  changedSubtitles,
  changedTrack,
  changedPlayerVisibility,
  changedResolution,
  pipStart, // Fire when start PIP by tap button in UI (not when close app).
  pipStop, // Fire when start PIP by tap button in UI (not when open app from PIP).
  setupDataSource,
  bufferingStart,
  bufferingUpdate,
  bufferingEnd,
  changedPlaylistItem,
  setDuration,
  enteringPIP, // Fire when start PIP by tap button in UI and close app.
  exitingPIP, // Fire when start PIP by tap button in UI and open app from PIP.
  tapExternalPlayButton, // Android only. Fire when tap play button from outside the app (e.g. PIP, Notification).
  tapExternalPauseButton, // Android only. Fire when tap pause button from outside the app (e.g. PIP, Notification).
}
