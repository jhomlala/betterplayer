## DRM configuration
To configure DRM for your data source, use drmConfiguration parameter. 
Supported DRMs:

* Token based (authorization header): Android/iOS
* Widevine (licensue url + headers): Android
* Fairplay EZDRM (certificate url, license url): iOS

Additional DRM types may be added in the future.

Token based:
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
````

Widevine (license url based):
```dart
BetterPlayerDataSource _widevineDataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "url",
    drmConfiguration: BetterPlayerDrmConfiguration(
        drmType: BetterPlayerDrmType.widevine,
        licenseUrl:"licenseUrl",
        headers: {"header": "value"}
    ),
);
```
Fairplay:

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

ClearKey (only supported in Android):

A ClearKey MP4 file can be generated with MP4Box as follow:

- Create drm_file.xml with the following contents.
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
   <CrypTrack IV_size="8" first_IV="0xbb5738fe08f11341" isEncrypted="1" saiSavedBox="senc" trackID="2">
    <key KID="f3c5e0361e6654b28f8049c778b23946" value="a4631a153a443df9eed0593043db7519"/>
  </CrypTrack>

</GPACDRM>


```
- Create the mp4 container using  [MP4Box](https://gpac.wp.imt.fr/)
  - MP4Box -crypt drm_file.xml  testvideo.mp4  -out testvideo_encrypt_tmp.mp4
  - MP4Box -frag 240000 testvideo_encrypt_tmp.mp4 -out testvideo_encrypt.mp4 (need to create multi segment mp4 file as ExoPlayer does not read the pssh block on a single segment mp4 file)
```dart

    var _clearKeyDataSourceFile = BetterPlayerDataSource(
      BetterPlayerDataSourceType.file,
      await Utils.getFileUrl(Constants.fileTestVideoEncryptUrl),
      drmConfiguration: BetterPlayerDrmConfiguration(
          drmType: BetterPlayerDrmType.clearKey,
          clearKey: BetterPlayerClearKeyUtils.generate({
            "f3c5e0361e6654b28f8049c778b23946":
                "a4631a153a443df9eed0593043db7519",
            "abba271e8bcf552bbd2e86a434a9a5d9":
                "69eaa802a6763af979e8d1940fb88392"
          })),
    );
