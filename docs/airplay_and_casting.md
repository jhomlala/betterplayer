---
id: airplay_and_casting
title: AirPlay & Remote Playback
---

# AirPlay & Remote Playback

Better Player supports wireless video routing to Apple TV, smart TVs, and remote screens without adding third-party SDK dependencies or increasing your binary size.

## Native AirPlay (iOS & macOS)

AirPlay works natively on iOS and macOS via Apple's `AVPlayer` and `AVRoutePickerView`. 

When AirPlay is enabled, an AirPlay icon appears in the player's top bar on supported Apple devices. Tapping the button opens the standard system route picker modal so viewers can connect to Apple TV or AirPlay 2-compatible receivers.

### Enabling AirPlay Controls

AirPlay is enabled by default in `PlayerControlsConfiguration`:

```dart
var betterPlayerConfiguration = PlayerConfiguration(
  controlsConfiguration: PlayerControlsConfiguration(
    enableAirPlay: true,
  ),
);
```

To hide the button, set `enableAirPlay: false`.

### Programmatic Control & State Monitoring

You can open the picker and monitor connection state directly from `BetterPlayerController`:

```dart
// Check active state
bool isAirPlayConnected = controller.isAirPlayActive;

// Open the native route picker programmatically
await controller.showAirPlayPicker();

// Listen to connection changes
controller.addEventsListener((event) {
  if (event.betterPlayerEventType == PlayerEventType.externalPlaybackChanged) {
    PlayerLogger.info(message: 'External playback active: ${controller.isAirPlayActive}');
  }
});
```

### Customizing Icons

Customize the idle and active icons in `PlayerControlsConfiguration`:

```dart
PlayerControlsConfiguration(
  enableAirPlay: true,
  airPlayIcon: Icons.airplay,
  airPlayActiveIcon: Icons.airplay_rounded,
  castIcon: Icons.cast,
  castConnectedIcon: Icons.cast_connected,
)
```

## Remote Playback (Web)

On web browsers, Better Player uses the W3C Remote Playback API (`HTMLMediaElement.remote`) and Apple Safari WebKit target picker (`webkitShowPlaybackTargetPicker()`).

When the browser detects an available target (such as Apple TV or a casting receiver on the local network), the route picker opens when you tap the AirPlay / Remote button or invoke `controller.showExternalPlaybackPicker()`.

## Pluggable Casting Architecture (`PlayerCastExtension`)

To keep core Better Player lightweight (~1-2 MB total footprint), Google Cast (Chromecast) and custom casting protocols do not live in the core package. Bundling the Google Cast SDK would force every Flutter app to carry 20-30 MB of Google Play Services libraries even if they only needed a local video player.

Instead, Better Player provides `PlayerCastExtension`. Companion packages can implement this interface to connect any casting backend directly into the core player lifecycle.

### Interface Contract

```dart
abstract class PlayerCastExtension extends BetterPlayerExtension {
  const PlayerCastExtension();

  /// Whether video currently casts to an external receiver.
  bool get isCasting;

  /// Stream that emits changes to the casting state.
  Stream<bool> get castingStream;

  /// Name of the target device that receives the stream.
  String? get targetDeviceName;

  /// Shows the device picker or connection interface.
  Future<void> showCastPicker();
}
```

When an extension implementing `PlayerCastExtension` is registered on `BetterPlayerController`, the player automatically coordinates casting state, updates the Cast button in the top bar, and synchronizes playback events.
