/// The lifecycle state of a media download.
///
/// A download moves forward through these states. It never goes back to
/// [queued] after it started, and [completed] is final.
enum DownloadState {
  /// The request is accepted and waits for the engine to start it.
  queued,

  /// The engine is storing segments in the download cache.
  downloading,

  /// The download is paused and can be resumed without losing progress.
  paused,

  /// Every segment is stored and the media plays without network access.
  completed,

  /// The download stopped because of an error.
  failed,
}
