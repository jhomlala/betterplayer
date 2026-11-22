import 'package:meta/meta.dart';

/// Configuration options for Chromecast integration and picker UI.
@immutable
class CastConfiguration {
  /// Creates a Cast configuration.
  const CastConfiguration({
    this.receiverAppId = 'CC1AD845',
    this.autoReconnect = true,
    this.heartbeatInterval = const Duration(seconds: 5),
    this.heartbeatTimeout = const Duration(seconds: 15),
    this.connectTimeout = const Duration(seconds: 10),
    this.pickerTitle = 'Cast to a device',
    this.scanningText = 'Searching for Cast devices...',
    this.noDevicesText = 'No Cast devices found on local network.',
    this.disconnectText = 'Disconnect',
  });

  /// Application ID to launch on the receiver. Defaults to Google's Default Media Receiver ('CC1AD845').
  final String receiverAppId;

  /// Whether to attempt rejoining an existing session or reconnecting if dropped.
  final bool autoReconnect;

  /// Interval between heartbeat PING messages.
  final Duration heartbeatInterval;

  /// Maximum time to wait for a PONG response before considering connection lost.
  final Duration heartbeatTimeout;

  /// Maximum time allowed for initial TLS connection and handshake.
  final Duration connectTimeout;

  /// Title displayed at top of device picker modal sheet.
  final String pickerTitle;

  /// Text displayed when discovery is scanning.
  final String scanningText;

  /// Text displayed when no devices have been discovered yet.
  final String noDevicesText;

  /// Button label for disconnecting from an active cast receiver.
  final String disconnectText;
}
