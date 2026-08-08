## Install

1. Add this to your **pubspec.yaml** file:

```yaml
dependencies:
  better_player: ^0.1.0
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
   You need to change these settings in order to run Better Player on iOS:
* Set deployment info of your project to **min. iOS 11.0 version**.
* Set Swift 5 version.

5. (Required) Android configuration. 
   You need to change these settings in order to run Better Player on Android:
* Set compileSdkVersion to *34*.
* Set kotlin version to *2.2.20*.
* Enable multidex.

6. (Optional) Additional iOS configuration

Add this into your `info.plist` file to support full screen rotation (Better Player will rotate screen to horizontal position when full screen is enabled):

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
   <string>UIInterfaceOrientationPortrait</string>
   <string>UIInterfaceOrientationLandscapeLeft</string>
   <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```
