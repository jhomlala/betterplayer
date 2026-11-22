# Better Player Cast

Chromecast extension for Better Player. Stream video to Chromecast and Google TV devices without bundling heavy native Google Play Services Cast SDKs.

## Features

- **Lean wire protocol**: Connects directly via pure Dart CastV2 over TLS, avoiding 20-30 MB native SDK overhead.
- **Native mDNS discovery**: Discovers devices on local network without Apple multicast entitlement hurdles.
- **Unified controls**: Hooks into `BetterPlayerController` via `PlayerCastExtension`, syncing play, pause, seek, volume, and playback state directly with the player UI.

## Installation

Add `better_player_cast` to your `pubspec.yaml`:

```bash
flutter pub add better_player_cast
```

### Platform Configuration

#### iOS & macOS

Add local network permissions and the Google Cast Bonjour service to `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Required to discover and connect to Chromecast devices on your local network.</string>
<key>NSBonjourServices</key>
<array>
  <string>_googlecast._tcp</string>
</array>
```

#### Android

Ensure network permissions are in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Quick Start

Register `BetterPlayerCastExtension` on your `PlayerConfiguration`:

```dart
import 'package:better_player/better_player.dart';
import 'package:better_player_cast/better_player_cast.dart';

final castExtension = BetterPlayerCastExtension(
  contextProvider: () => navigatorKey.currentContext,
);

final controller = BetterPlayerController(
  PlayerConfiguration(
    extensions: [castExtension],
  ),
  betterPlayerDataSource: PlayerDataSource(
    DataSourceType.network,
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  ),
);
```

When registered, tapping the cast button in Better Player's control bar automatically opens the device picker and routes video playback to the selected receiver.
