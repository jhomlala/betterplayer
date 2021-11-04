## Install

1. Add this to your **pubspec.yaml** file:

```yaml
dependencies:
  better_player: ^0.0.76
```

2. Install it

```bash
$ flutter pub get
```

3. Import it

```dart
import 'package:better_player/better_player.dart';
```

4. (Required) iOS configuration

Set deployment info of your project to **min. iOS 11.0 version**. This can be done in XCode in Runner -> General configuration screen.

5. (Optional) Additional iOS configuration

Add this into your `info.plist` file to support full screen rotation (Better Player will rotate screen to horizontal position when full screen is enabled):

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
   <string>UIInterfaceOrientationPortrait</string>
   <string>UIInterfaceOrientationLandscapeLeft</string>
   <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```
