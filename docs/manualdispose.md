## Manual dispose

Better Player disposes automatically `BetterPlayerController` when `BetterPlayer` widget will be removed from widget tree (when `dispose` method of `BetterPlayer` widget will be called by Flutter framework).

If you're seeing error: `A VideoPlaverController was used after being disposed`, this means that your `BetterPlayer` widget got diposed and also `BetterPlayerController` got disposed. If you're building complex UI, you may decide whether to dispose `BetterPlayerController` manually. To enable manual disposal you need to set `autoDispose` flag to false in `BetterPlayerConfiguration`:

```dart
BetterPlayerConfiguration betterPlayerConfiguration =
    BetterPlayerConfiguration(
        autoDispose: false,
    );
```

Now, when your `BetterPlayer` widget got disposed, your `BetterPlayerController` will stay alive and you need to dispose it manually once you'll know that you don't need that anymore:

```dart
betterPlayerController.dispose();
```