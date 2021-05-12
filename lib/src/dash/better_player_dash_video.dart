import 'package:better_player/src/asms/better_player_asms_track.dart';

///Representation of DASH audio track
class BetterPlayerDashVideo {
  ///List of Tracks
  final List<BetterPlayerAsmsTrack>? tracks;

  ///mimeType of the video track
  final String? mimeType;

  final bool? segmentAlignment;

  BetterPlayerDashVideo({this.tracks, this.mimeType, this.segmentAlignment});
}
