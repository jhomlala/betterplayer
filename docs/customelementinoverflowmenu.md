## Custom element in overflow menu
You can use `BetterPlayerControlsConfiguration` to add custom element to the overflow menu:

```dart
controlsConfiguration: BetterPlayerControlsConfiguration(
            overflowMenuCustomItems: [
                BetterPlayerOverflowMenuItem(
                    Icons.account_circle_rounded,
                    "Custom element",
                    () => print("Click!"),
                )
            ],
        ),
```