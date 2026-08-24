# Custom Overflow Menu Items

You can extend the player's overflow menu by adding custom elements using the `BetterPlayerControlsConfiguration`.

## Implementation Example

```dart
controlsConfiguration: BetterPlayerControlsConfiguration(
    overflowMenuCustomItems: [
        BetterPlayerOverflowMenuItem(
            Icons.account_circle_rounded,
            "User Profile",
            () => BetterPlayerUtils.log("Custom Action Executed!"),
        )
    ],
),
```

Custom items will appear alongside the standard playback speed, subtitles, and quality options.
