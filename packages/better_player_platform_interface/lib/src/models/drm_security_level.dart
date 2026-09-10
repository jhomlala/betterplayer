/// Security level used for DRM.
///
/// On Android it maps to Widevine security level (e.g. "L1", "L3").
/// On Web it maps to Shaka Player's videoRobustness (e.g. "SW_SECURE_CRYPTO", "HW_SECURE_ALL").
enum DrmSecurityLevel {
  /// Widevine L1 (Android)
  l1,

  /// Widevine L3 (Android)
  l3,

  /// SW_SECURE_CRYPTO (Web)
  swSecureCrypto,

  /// SW_SECURE_DECODE (Web)
  swSecureDecode,

  /// HW_SECURE_CRYPTO (Web)
  hwSecureCrypto,

  /// HW_SECURE_DECODE (Web)
  hwSecureDecode,

  /// HW_SECURE_ALL (Web)
  hwSecureAll,
}
