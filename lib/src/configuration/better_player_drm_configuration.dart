import 'package:better_player/src/configuration/better_player_drm_type.dart';
///Configuration of DRM used to protect data source
class BetterPlayerDrmConfiguration{
  ///Type of DRM
  final BetterPlayerDrmType drmType;

  ///Token used for AES authorization
  final String token;

  BetterPlayerDrmConfiguration({this.drmType, this.token});
}