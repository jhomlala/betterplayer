/// Connection state of a Cast session.
enum CastSessionState {
  /// No active connection to a Cast receiver.
  disconnected,

  /// Connecting or performing TLS handshake.
  connecting,

  /// Connected and ready to cast media.
  connected,

  /// Reconnecting to receiver after transient drop.
  reconnecting,
}
