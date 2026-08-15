# Handling Multiple Gestures

In scenarios where you need to wrap the `BetterPlayer` widget with a `GestureDetector`, you should use `BetterPlayerMultipleGestureDetector`. This ensures that gestures are correctly propagated and do not conflict with the player's internal gesture handling.

## Implementation Example

```dart
BetterPlayerMultipleGestureDetector(
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(controller: _betterPlayerController),
    ),
    onTap: () {
      print("Outer Tap Detected!");
    },
);
```

## Supported Gestures
*   `onTap`
*   `onDoubleTap`
*   `onLongPress`

For any other gesture types, you can continue to use the standard Flutter `GestureDetector`.
