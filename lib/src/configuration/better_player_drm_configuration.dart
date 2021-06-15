import 'package:better_player/src/configuration/better_player_drm_type.dart';

///Configuration of DRM used to protect data source
class BetterPlayerDrmConfiguration {
  ///Type of DRM
  final BetterPlayerDrmType? drmType;

  ///Parameter used only for token encrypted DRMs
  final String? token;

  ///Url of license server, used only for WIDEVINE/PLAYREADY DRM
  final String? licenseUrl;

  ///Url of fairplay certificate
  final String? certificateUrl;

  ///Additional headers send with auth request, used only for WIDEVINE DRM
  final Map<String, String>? headers;

  BetterPlayerDrmConfiguration({
    this.drmType,
    this.token,
    this.licenseUrl,
    this.certificateUrl,
    this.headers,
  });
}
