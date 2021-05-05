import 'package:better_player/src/dash/better_player_dash_track.dart';
import 'package:better_player/src/hls/hls_parser/mime_types.dart';

///Representation of DASH audio track
class BetterPlayerDashVideo {
  ///List of Tracks
  final List<BetterPlayerDashTrack>? tracks;

  ///mimeType of the video track
  final String? mimeType;

  final bool? segmentAlignment;

  BetterPlayerDashVideo({this.tracks, this.mimeType, this.segmentAlignment});
}
