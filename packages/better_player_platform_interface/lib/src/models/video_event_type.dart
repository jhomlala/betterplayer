/// Type of the event.
///
/// Emitted by the platform implementation when the video is initialized or
/// completed or to communicate buffering events.
enum VideoEventType {
  /// The video has been initialized.
  initialized,

  /// The playback has ended.
  completed,

  /// Updated information on the buffering state.
  bufferingUpdate,

  /// The video started to buffer.
  bufferingStart,

  /// The video stopped to buffer.
  bufferingEnd,

  /// The video is set to play
  play,

  /// The video is set to pause
  pause,

  /// The video is set to given to position
  seek,

  /// The video is displayed in Picture in Picture mode
  pipStart,

  /// Picture in picture mode has been dismissed
  pipStop,

  /// The video size has changed.
  changedSize,

  /// An unknown event has been received.
  unknown,
}
