# better_player_android_surfaceview

Renders [better_player](https://pub.dev/packages/better_player) video on
Android through a native `SurfaceView` instead of Flutter's `Texture`.

Some budget chipsets cannot share an OpenGL texture with the hardware decoder:
audio plays and the decoder runs, but the screen stays black. A `SurfaceView`
hands frames straight to the hardware composer and avoids that path.

## Usage

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) BetterPlayerAndroidSurfaceView.registerWith();
  runApp(const MyApp());
}
```

By default every player uses a SurfaceView. To try Texture first and fall back
only when it fails, flip the flag around the call that creates the player (it
is read synchronously, before the first `await` in `create()`):

```dart
BetterPlayerAndroidSurfaceView.useSurfaceViewForNewPlayers = false; // Texture
final setup = controller.setupDataSource(source);
BetterPlayerAndroidSurfaceView.useSurfaceViewForNewPlayers = true;
await setup;
```

`BetterPlayerAndroidSurfaceView.isSurfaceView(textureId)` tells which pipeline a
player ended up on.

## Trade-offs

A SurfaceView punches a hole through the Flutter window. `ClipRRect`, opacity,
animations and rotation transforms do not apply to the video, and it is
composited with hybrid composition, so Z-order against overlays and dialogs
differs from Texture. Use it as a fallback, not as the default.

## How it fits together

* **Dart** – `BetterPlayerAndroidSurfaceView extends BetterPlayerAndroid` and
  overrides only player creation and `buildView()`. Everything else is
  inherited.
* **Native** – a `PlatformViewFactory` finds the player by id in
  `BetterPlayerRegistry` and keeps a per-player stack of surfaces (inline view
  plus the fullscreen route above it; newest valid surface wins).
* **No MethodChannel** – the player is created over JNI like the rest of the
  project, through `BetterPlayerApi.createSurfacePlayer`.
* **No dummy texture** – a SurfaceView player never touches the
  `TextureRegistry`; its id comes from an atomic counter.

## What it needs from `better_player_android`

Three small, additive changes; Texture behaviour is unchanged:

1. `BetterPlayerApi.createSurfacePlayer(context, callback)` – a player with no
   texture and an id from an atomic counter.
2. `BetterPlayer.setVideoSurface(Surface?)` – ignored for texture players and
   after `dispose()`.
3. `BetterPlayerRegistry` – live players by id; each player removes itself in
   `dispose()`.
