# better_player

The app-facing package for the Better Player plugin.

Better Player is a powerful video player for Flutter, built on top of the official `video_player` plugin and inspired by `Chewie`. It solves common playback issues, provides extensive configuration options, and handles complex media use cases out of the box.

This is a federated plugin. Platform-specific implementations are located in:
* `better_player_android`
* `better_player_ios`

The platform interface is defined in:
* `better_player_platform_interface`

## Usage

Add Better Player to your `pubspec.yaml`:

```yaml
dependencies:
  better_player: ^1.0.0
```

For detailed documentation, visit: https://jhomlala.github.io/betterplayer/
