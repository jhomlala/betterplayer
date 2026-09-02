import 'package:better_player/src/asms/player_asms_audio_track.dart';
import 'package:better_player/src/asms/player_asms_subtitle.dart';
import 'package:better_player/src/asms/player_asms_track.dart';

class PlayerAsmsDataHolder {
  PlayerAsmsDataHolder({this.tracks, this.subtitles, this.audios});
  List<PlayerAsmsTrack>? tracks;
  List<PlayerAsmsSubtitle>? subtitles;
  List<PlayerAsmsAudioTrack>? audios;
}
