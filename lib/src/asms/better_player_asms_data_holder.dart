import 'better_player_asms_track.dart';
import 'better_player_asms_audio_track.dart';
import 'better_player_asms_subtitle.dart';

class BetterPlayerAsmsDataHolder {
  List<BetterPlayerAsmsTrack>? videos;
  List<BetterPlayerAsmsSubtitle>? subtitles;
  List<BetterPlayerAsmsAudioTrack>? audios;

  BetterPlayerAsmsDataHolder({this.videos, this.subtitles, this.audios});
}