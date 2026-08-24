---
id: drmconfiguration
title: DRM Configuration
---

# DRM Configuration

Better Player provides robust support for Digital Rights Management (DRM) to protect your video content. DRM is configured using the `drmConfiguration` parameter within the `BetterPlayerDataSource`.

## Supported DRM Types

Currently, Better Player supports the following DRM mechanisms:

*   **Token-Based (Authorization Header)**: Supported on both Android and iOS.
*   **Widevine (License URL + Headers)**: Supported on Android.
*   **FairPlay EZDRM (Certificate URL + License URL)**: Supported on iOS.
    > [!IMPORTANT]
    > **Real Device Required**: DRM playback (Widevine and FairPlay) typically requires a physical device. Playback on emulators or simulators is not supported and may fail with protocol errors.
*   **ClearKey**: Supported on Android.

---

### Token-Based DRM
Used when the license is retrieved via a simple authorization token.

```dart
BetterPlayerDataSource dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "url",
    videoFormat: BetterPlayerVideoFormat.hls,
    drmConfiguration: BetterPlayerDrmConfiguration(
        drmType: BetterPlayerDrmType.token,
        token: "Bearer=token",
    ),
);
```

### Widevine DRM (Android)
Used for license retrieval based on a license URL.

```dart
BetterPlayerDataSource _widevineDataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "url",
    drmConfiguration: BetterPlayerDrmConfiguration(
        drmType: BetterPlayerDrmType.widevine,
        licenseUrl: "https://your-license-server.com/license",
        headers: {"Authorization": "Bearer token"}
    ),
);
```

### FairPlay DRM (iOS)
Requires a certificate URL and a license URL.

```dart
BetterPlayerDataSource _fairplayDataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    Constants.fairplayHlsUrl,
    drmConfiguration: BetterPlayerDrmConfiguration(
        drmType: BetterPlayerDrmType.fairplay,
        certificateUrl: Constants.fairplayCertificateUrl,
        licenseUrl: Constants.fairplayLicenseUrl,
    ),
);
```

---

### ClearKey DRM (Android)

ClearKey content can be generated using tools like [MP4Box](https://gpac.wp.imt.fr/). 

#### 1. Generate Protected Content
Create a `drm_file.xml` with your key specifications:

```xml
<GPACDRM type="CENC AES-CTR">
  <DRMInfo type="pssh" version="1">
    <BS ID128="1077efecc0b24d02ace33c1e52e2fb4b"/>
    <BS bits="32" value="1"/>
    <BS ID128="cd7eb9ff88f34caeb06185b00024e4c2"/>
  </DRMInfo>
  <CrypTrack IV_size="8" first_IV="0xbb5738fe08f11341" isEncrypted="1" saiSavedBox="senc" trackID="1">
    <key KID="f3c5e0361e6654b28f8049c778b23946" value="a4631a153a443df9eed0593043db7519"/>
  </CrypTrack>
</GPACDRM>
```

Run the following MP4Box commands:
```bash
# Encrypt the video
MP4Box -crypt drm_file.xml testvideo.mp4 -out testvideo_encrypt_tmp.mp4

# Fragment the video (Required for ExoPlayer to read pssh blocks)
MP4Box -frag 240000 testvideo_encrypt_tmp.mp4 -out testvideo_encrypt.mp4
```

#### 2. Configure ClearKey in Data Source
```dart
var _clearKeyDataSource = BetterPlayerDataSource(
  BetterPlayerDataSourceType.file,
  await Utils.getFileUrl(Constants.fileTestVideoEncryptUrl),
  drmConfiguration: BetterPlayerDrmConfiguration(
      drmType: BetterPlayerDrmType.clearKey,
      clearKey: BetterPlayerClearKeyUtils.generate({
        "f3c5e0361e6654b28f8049c778b23946": "a4631a153a443df9eed0593043db7519",
      })
  ),
);
```
