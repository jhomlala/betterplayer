import 'better_player_asms_track.dart';
import 'better_player_asms_audio_track.dart';
import 'better_player_asms_subtitle.dart';

class BetterPlayerAsmsDataHolder {
  List<BetterPlayerAsmsTrack>? tracks;
  List<BetterPlayerAsmsSubtitle>? subtitles;
  List<BetterPlayerAsmsAudioTrack>? audios;

  BetterPlayerAsmsDataHolder({this.tracks, this.subtitles, this.audios});
}