/// Standard CastV2 namespace URNs and default identifiers.
abstract final class CastNamespaces {
  /// Transport connection namespace.
  static const String connection = 'urn:x-cast:com.google.cast.tp.connection';

  /// Heartbeat PING/PONG namespace.
  static const String heartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';

  /// Receiver lifecycle namespace (LAUNCH, STOP, GET_STATUS).
  static const String receiver = 'urn:x-cast:com.google.cast.receiver';

  /// Media playback namespace (LOAD, PLAY, PAUSE, SEEK).
  static const String media = 'urn:x-cast:com.google.cast.media';

  /// Default Google Media Receiver application ID.
  static const String defaultReceiverAppId = 'CC1AD845';

  /// Standard sender source identifier.
  static const String defaultSenderId = 'sender-0';

  /// Standard root receiver destination identifier.
  static const String defaultReceiverId = 'receiver-0';
}
