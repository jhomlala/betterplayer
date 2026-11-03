import 'package:meta/meta.dart';

/// Represents HLS / DASH track which can be played within player
@immutable
class PlayerAsmsTrack {
  const PlayerAsmsTrack(
    this.id,
    this.width,
    this.height,
    this.bitrate,
    this.frameRate,
    this.codecs,
    this.mimeType,
  );

  factory PlayerAsmsTrack.defaultTrack() {
    return const PlayerAsmsTrack('', 0, 0, 0, 0, '', '');
  }

  ///Id of the track
  final String? id;

  ///Width in px of the track
  final int? width;

  ///Height in px of the track
  final int? height;

  ///Bitrate in px of the track
  final int? bitrate;

  ///Frame rate of the track
  final int? frameRate;

  ///Codecs of the track
  final String? codecs;

  ///mimeType of the video track
  final String? mimeType;

  @override
  int get hashCode =>
      Object.hash(id, width, height, bitrate, frameRate, codecs, mimeType);

  @override
  bool operator ==(Object other) {
    return other is PlayerAsmsTrack &&
        id == other.id &&
        width == other.width &&
        height == other.height &&
        bitrate == other.bitrate &&
        frameRate == other.frameRate &&
        codecs == other.codecs &&
        mimeType == other.mimeType;
  }

  @override
  String toString() =>
      'PlayerAsmsTrack(id: $id, ${width}x$height @ ${bitrate}bps)';
}
