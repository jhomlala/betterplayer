## Install

1. Add this to your **pubspec.yaml** file:

```yaml
dependencies:
  better_player: ^0.0.72
```

2. Install it

```bash
$ flutter pub get
```

3. Import it

```dart
import 'package:better_player/better_player.dart';
```

4. (Optional) iOS configuration

Add this into your `info.plist` file to support full screen rotation (Better Player will rotate screen to horizontal position when full screen is enabled):

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
   <string>UIInterfaceOrientationPortrait</string>
   <string>UIInterfaceOrientationLandscapeLeft</string>
   <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```