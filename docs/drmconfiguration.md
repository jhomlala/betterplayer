## DRM configuration
To configure DRM for your data source, use drmConfiguration parameter. 
Supported DRMs:

* Token based (authorization header): Android/iOS
* Widevine (licensue url + headers): Android
* Fairplay EZDRM (certificate url): iOS

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
    ),
);
```