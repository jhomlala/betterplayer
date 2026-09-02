/// Represents HLS / DASH track which can be played within player
class PlayerAsmsTrack {
  PlayerAsmsTrack(
    this.id,
    this.width,
    this.height,
    this.bitrate,
    this.frameRate,
    this.codecs,
    this.mimeType,
  );

  factory PlayerAsmsTrack.defaultTrack() {
    return PlayerAsmsTrack('', 0, 0, 0, 0, '', '');
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
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(dynamic other) {
    return other is PlayerAsmsTrack &&
        width == other.width &&
        height == other.height &&
        bitrate == other.bitrate &&
        frameRate == other.frameRate &&
        codecs == other.codecs &&
        mimeType == other.mimeType;
  }
}
