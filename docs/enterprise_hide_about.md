---
id: enterprise_hide_about
title: Hide the About Menu
---

# Hide the About Menu

Better Player Enterprise allows suppressing the **About** option in the 3-dots overflow menu. This feature requires an enterprise license with the `hide_about` capability.

## Configuration

Initialize enterprise licensing during application startup, then attach `BetterPlayerEnterpriseExtension` with `hideAbout: true` to your `PlayerConfiguration`:

```dart
import 'package:better_player/better_player.dart';
import 'package:better_player_enterprise/better_player_enterprise.dart';

final controller = BetterPlayerController(
  PlayerConfiguration(
    extensions: [
      const BetterPlayerEnterpriseExtension(hideAbout: true),
    ],
  ),
);
```

Add the extension to every controller instance where you want the About item removed (including playlist and list player controllers).

## Verification and Fallback Behavior

The capability check runs each time the user opens the 3-dots menu:

* If the enterprise license is active, valid, and contains the `hide_about` capability, the About menu item is suppressed.
* If the license is expired, invalid, missing, or lacks `hide_about`, the About item displays normally.
* Main video playback continues uninterrupted in all licensing states.

## Requesting the Capability

To obtain an enterprise license with `hide_about`, contact `betterplayer@hasoft.pl`.
