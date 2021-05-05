///Representation of DASH audio track
class BetterPlayerDashAudioTrack {
  ///Audio index in dsh xml
  final int? id;

  ///segmentAlignment
  final bool? segmentAlignment;

  ///Description of the audio
  final String? label;

  ///Language code
  final String? language;

  ///mimeType of the audio track
  final String? mimeType;

  BetterPlayerDashAudioTrack({this.id, this.segmentAlignment, this.label, this.language, this.mimeType});
}
