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

## `mpv-2.dll` requirement

`better_player_windows` relies on `mpv-2.dll` (or `libmpv-2.dll`) for media playback and software frame rendering. Due to its binary size (~35 MB), the native DLL is not packaged with the pub.dev distribution by design.

To run your Windows application:
1. Download the `mpv-2.dll` Windows 64-bit build (e.g. from [mpv-player-windows on SourceForge](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/)).
2. Place `mpv-2.dll` into your application's output directory alongside the executable (e.g. `build/windows/x64/runner/Debug/` or `Release/`), or place it into `packages/better_player_windows/windows/libs/mpv-2.dll` so CMake automatically copies it on build.
