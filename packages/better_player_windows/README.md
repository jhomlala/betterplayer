# better_player_windows

Windows implementation of the [better_player](https://pub.dev/packages/better_player) plugin.

## Usage

This package is a federated plugin implementation. Do not depend on it directly. Use the main `better_player` package instead:

```yaml
dependencies:
  better_player: ^1.20.0
```

## Requirements

* **Windows**: Windows 10 (version 1809) or higher (64-bit).
* **Graphics**: DirectX 11 or compatible graphics hardware or driver.

## Features

* High-performance playback engine powered by `libmpv` and FFmpeg.
* Video rendering via Flutter's `TextureRegistrar`.
* Full HLS adaptive bitrate streaming (`.m3u8`) and MPEG-DASH (`.mpd`).
* RTSP live streaming support.
* Subtitle parsing and audio track switching.
* Custom HTTP headers and network buffering configuration.
