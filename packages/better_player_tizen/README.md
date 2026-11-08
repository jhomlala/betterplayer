<p align="center">
  <img src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/logo.png" width="180px" alt="Better Player Logo">
</p>

# better_player_tizen

Tizen implementation of the [better_player](https://pub.dev/packages/better_player) plugin.

This package provides experimental video playback for Samsung Smart TVs and Tizen devices via the native Tizen Multimedia Player API (`<player.h>`).

## Usage

This package is a federated plugin implementation. Add both `better_player` and `better_player_tizen` to your dependencies:

```yaml
dependencies:
  better_player: ^1.33.0
  better_player_tizen:
    path: packages/better_player_tizen
```

## Manifest Privileges

To play network streams or local media files on Tizen, add these privileges to your `tizen-manifest.xml`:

```xml
<privileges>
    <privilege>http://tizen.org/privilege/internet</privilege>
    <privilege>http://tizen.org/privilege/mediastorage</privilege>
    <privilege>http://tizen.org/privilege/externalstorage</privilege>
</privileges>
```

## Current Status (Experimental)

Supported core operations:
* Network (`http`/`https`) and local file playback
* Play, pause, seek, volume, speed, and looping
* Lifecycle and playback event streams (`initialized`, `completed`, `bufferingUpdate`, `play`, `pause`)

Features not yet wired on Tizen:
* DRM protection (Widevine / FairPlay)
* Custom caching and pre-caching
* Picture-in-picture mode
