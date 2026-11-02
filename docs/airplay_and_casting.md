---
id: airplay_and_casting
title: AirPlay & Remote Playback
---

# AirPlay & Remote Playback

Route video to Apple TV, smart TVs, and wireless receivers without bundling heavy third-party SDKs into your app.

## Native AirPlay (iOS & macOS)

iOS and macOS use `AVPlayer` and `AVRoutePickerView` directly. When enabled, an AirPlay button appears in the top control bar. Tapping it opens the system route picker.

### Configuration

AirPlay is enabled by default in `PlayerControlsConfiguration`:

```dart
final configuration = PlayerConfiguration(
  controlsConfiguration: const PlayerControlsConfiguration(
    enableAirPlay: true,
  ),
);
```

Set `enableAirPlay: false` to hide the button. On platforms without native AirPlay (Android, Windows, Linux), the button stays hidden automatically unless a `PlayerCastExtension` is registered.

### Programmatic Control

Open the route picker or check the connection state from `BetterPlayerController`:

```dart
// Check active state
final isAirPlayConnected = controller.isAirPlayActive;

// Open the native route picker
await controller.showAirPlayPicker();

// Listen for route changes
controller.addEventsListener((event) {
  if (event.betterPlayerEventType == PlayerEventType.externalPlaybackChanged) {
    PlayerLogger.info(
      message: 'External playback active: ${controller.isExternalPlaybackActive}',
    );
  }
});
```

### Custom Icons

Override the idle and active icons in `PlayerControlsConfiguration`:

```dart
const PlayerControlsConfiguration(
  enableAirPlay: true,
  airPlayIcon: Icons.airplay_outlined,
  airPlayActiveIcon: Icons.airplay,
  castIcon: Icons.cast_outlined,
  castConnectedIcon: Icons.cast_connected_outlined,
)
```

## Remote Playback (Web)

On web browsers, Better Player uses the W3C Remote Playback API (`HTMLMediaElement.remote`) and falls back to Safari's WebKit target picker (`webkitShowPlaybackTargetPicker()`).

Tapping the AirPlay button in the web control bar or calling `controller.showExternalPlaybackPicker()` opens the browser's device picker.

## Pluggable Casting (`PlayerCastExtension`)

Core Better Player does not bundle the Google Cast SDK. Including Google Play Services Cast libraries would add 20-30 MB to every app binary, even for apps that only play local video.

Instead, Better Player provides `PlayerCastExtension`. Companion packages implement this contract to hook Chromecast, DLNA, or custom protocols into the player UI and event loop.

```dart
abstract class PlayerCastExtension extends BetterPlayerExtension {
  const PlayerCastExtension();

  /// Whether video currently casts to an external receiver.
  bool get isCasting => false;

  /// Stream that emits changes to the casting state.
  Stream<bool> get castingStream => const Stream<bool>.empty();

  /// Name of the target device that receives the stream.
  String? get targetDeviceName => null;

  /// Opens the device picker or connection dialog.
  Future<void> showCastPicker();
}
```

Register your extension in `PlayerConfiguration(extensions: [myCastExtension])` or call `controller.registerExtension(myCastExtension)`. When registered:
- The top bar switches from the AirPlay icon to `castIcon` (and `castConnectedIcon` when active).
- Tapping the button calls `showCastPicker()`.
- Emissions on `castingStream` update the control bar and dispatch `PlayerEventType.externalPlaybackChanged`.
