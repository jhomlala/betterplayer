/// Preload strategy used by [BetterPlayerPool].
enum PlayerPreloadMode {
  /// Prepares the media source and pauses immediately once initialized.
  /// Minimum CPU and battery consumption.
  prepared,

  /// Prepares and plays the media at volume 0.0 to keep native codec
  /// and network buffers hot.
  muted,
}
