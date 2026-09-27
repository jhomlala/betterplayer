# DRM Configuration Reference

Configure Digital Rights Management (DRM) using `DrmConfiguration` inside `PlayerDataSource`.

> **Important**: Test Widevine and FairPlay on physical devices. Emulators and simulators often lack hardware-backed DRM support.

## Supported DRM Types (`DrmType`)

| `DrmType` | Platforms | Required Fields |
| :--- | :--- | :--- |
| `DrmType.token` | Android, iOS | `token` |
| `DrmType.widevine` | Android, Web (Shaka) | `licenseUrl` (optional `headers`, `drmSecurityLevel`) |
| `DrmType.fairplay` | iOS, Web (Shaka) | `certificateUrl`, `licenseUrl` |
| `DrmType.clearKey` | Android, Web | `clearKey` (generated via `BetterPlayerClearKeyUtils.generate`) |

## 1. Widevine (Android & Web)

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/protected.mpd',
  videoFormat: VideoFormat.dash,
  drmConfiguration: const DrmConfiguration(
    drmType: DrmType.widevine,
    licenseUrl: 'https://license.example.com/widevine',
    headers: {'Authorization': 'Bearer <token>'},
    drmSecurityLevel: DrmSecurityLevel.l3, // Android: .l1 or .l3
  ),
);
```

### `DrmSecurityLevel` Platform Rules

* **Android**: Use `DrmSecurityLevel.l1` (hardware-backed, required for HD/4K on many devices) or `DrmSecurityLevel.l3` (software crypto, default).
* **Web (Shaka Player)**: Maps to `videoRobustness`. Use `DrmSecurityLevel.swSecureCrypto`, `DrmSecurityLevel.swSecureDecode`, `DrmSecurityLevel.hwSecureCrypto`, `DrmSecurityLevel.hwSecureDecode`, or `DrmSecurityLevel.hwSecureAll`.
* Do not pass an Android level (`l1`/`l3`) on Web or vice versa; doing so throws an `UnsupportedError`. If targeting both Android and Web, select the `DrmSecurityLevel` conditionally with `kIsWeb`.

## 2. FairPlay (iOS & Web)

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/protected.m3u8',
  videoFormat: VideoFormat.hls,
  drmConfiguration: const DrmConfiguration(
    drmType: DrmType.fairplay,
    certificateUrl: 'https://license.example.com/fairplay.cer',
    licenseUrl: 'https://license.example.com/spc',
  ),
);
```

## 3. ClearKey (Android & Web)

Use `BetterPlayerClearKeyUtils.generate` with a map of hex key IDs (`KID`) to hex key values:

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/clearkey.mpd',
  drmConfiguration: DrmConfiguration(
    drmType: DrmType.clearKey,
    clearKey: BetterPlayerClearKeyUtils.generate({
      'f3c5e0361e6654b28f8049c778b23946': 'a4631a153a443df9eed0593043db7519',
    }),
  ),
);
```

## 4. Token-Based Authorization (Android & iOS)

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/stream.m3u8',
  videoFormat: VideoFormat.hls,
  drmConfiguration: const DrmConfiguration(
    drmType: DrmType.token,
    token: 'Bearer <token>',
  ),
);
```
