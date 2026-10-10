<p align="center">
  <img src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/logo.png" width="180px" alt="Better Player Logo">
</p>

# better_player_macos

macOS implementation of the [better_player](https://pub.dev/packages/better_player) plugin.

## Usage

This package is a federated plugin implementation. Do not depend on it directly. Use the main `better_player` package instead:

```yaml
dependencies:
  better_player: ^1.20.0
```

## Requirements

* **macOS**: 10.15 (Catalina) or higher.
* **App Sandbox**: If your macOS app uses App Sandbox (the default for Flutter desktop apps), enable outgoing network connections in `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

## Features

* Native `AVPlayer` playback engine.
* `AppKitView` platform view rendering backed by `AVPlayerLayer`.
* HLS adaptive streaming and progressive playback.
* FairPlay DRM and ClearKey support.
* Picture-in-Picture via `AVPictureInPictureController`.
* Caching and pre-caching.
