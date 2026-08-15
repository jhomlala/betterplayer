# Manual Disposal Management

By default, Better Player automatically manages the disposal of the `BetterPlayerController` when the `BetterPlayer` widget is removed from the widget tree (i.e., when its `dispose` method is called by the Flutter framework).

## When to Use Manual Disposal

In certain complex UI scenarios—such as when navigating between screens or using specific navigation patterns—you may encounter the following error:
`A VideoPlayerController was used after being disposed`.

This error typically indicates that the `BetterPlayer` widget was disposed of prematurely, causing the underlying `BetterPlayerController` to be disposed of while it was still needed. In such cases, you should manage the controller's lifecycle manually.

## Implementing Manual Disposal

To take control of the disposal process, set the `autoDispose` flag to `false` within your `BetterPlayerConfiguration`:

```dart
BetterPlayerConfiguration betterPlayerConfiguration =
    BetterPlayerConfiguration(
        autoDispose: false,
    );
```

### Manual Cleanup

When `autoDispose` is disabled, you are responsible for invoking the `dispose()` method on the `BetterPlayerController` once it is no longer required. Failing to do so may result in memory leaks.

```dart
// Call this when you are finished with the controller
betterPlayerController.dispose();
```
