<p align="center">
  <img src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/logo.png" width="180px" alt="Better Player Logo">
</p>

# better_player_linux

Linux implementation of the [better_player](https://pub.dev/packages/better_player) plugin.

## Usage

This package is a federated plugin implementation. Do not depend on it directly. Use the main `better_player` package instead:

```yaml
dependencies:
  better_player: ^1.29.0
```

## Requirements

* **Linux**: Any standard desktop distribution with GTK 3.0+ and `glibc` 2.31+.
* **libmpv**: `libmpv.so.2` or `libmpv.so.1` installed on the system.

### Installing `libmpv`

On Debian/Ubuntu:
```bash
sudo apt update
sudo apt install libmpv-dev libmpv2
```

On Fedora/RHEL:
```bash
sudo dnf install mpv-libs-devel
```

On Arch Linux:
```bash
sudo pacman -S mpv
```

## Features

* High-performance playback engine powered by `libmpv` and FFmpeg.
* Video rendering via Flutter's `FlPixelBufferTexture`.
* Full HLS adaptive bitrate streaming (`.m3u8`) and MPEG-DASH (`.mpd`).
* RTSP live streaming support.
* Subtitle parsing (SRT, WebVTT, TTML) and audio track switching.
* Custom HTTP headers and network buffering configuration.
