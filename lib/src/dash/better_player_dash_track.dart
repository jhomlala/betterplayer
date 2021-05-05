/// Represents DASH track which can be played within player
class BetterPlayerDashTrack {
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

  BetterPlayerDashTrack(this.id, this.width, this.height, this.bitrate, this.frameRate, this.codecs);

  factory BetterPlayerDashTrack.defaultTrack() {
    return BetterPlayerDashTrack('', 0, 0, 0, 0, '');
  }

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(dynamic other) {
    return other is BetterPlayerDashTrack &&
        width == other.width &&
        height == other.height &&
        bitrate == other.bitrate &&
        frameRate == other.frameRate &&
        codecs == other.codecs;
  }
}
