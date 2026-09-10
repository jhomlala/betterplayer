import 'package:better_player_platform_interface/src/models/drm_security_level.dart';
import 'package:better_player_platform_interface/src/models/drm_type.dart';

///Configuration of DRM used to protect data source
class DrmConfiguration {
  const DrmConfiguration({
    this.drmType,
    this.token,
    this.licenseUrl,
    this.certificateUrl,
    this.headers,
    this.clearKey,
    this.drmSecurityLevel,
  });

  ///Type of DRM
  final DrmType? drmType;

  ///Parameter used only for token encrypted DRMs
  final String? token;

  ///Url of license server
  final String? licenseUrl;

  ///Url of fairplay certificate
  final String? certificateUrl;

  ///ClearKey json object, used only for ClearKey protection. Only support for Android.
  final String? clearKey;

  ///Additional headers send with auth request, used only for WIDEVINE DRM
  final Map<String, String>? headers;

  ///Security level used for DRM.
  ///On Android it maps to Widevine security level (e.g. "L1", "L3").
  ///On Web it maps to Shaka Player's videoRobustness (e.g. "SW_SECURE_CRYPTO", "HW_SECURE_ALL").
  final DrmSecurityLevel? drmSecurityLevel;
}
