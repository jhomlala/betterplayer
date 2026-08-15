# Installation and Configuration

Follow these steps to integrate Better Player into your Flutter application.

## 1. Add Dependency

Add `better_player` to your `pubspec.yaml` file:

```yaml
dependencies:
  better_player: ^0.4.3
```

## 2. Install Package

Run the following command in your terminal to fetch the package:

```bash
flutter pub get
```

## 3. Import Package

Import the library into your Dart code:

```dart
import 'package:better_player/better_player.dart';
```

## 4. Platform-Specific Configuration

### iOS Configuration (Required)

To ensure Better Player functions correctly on iOS, apply the following settings:

*   **Deployment Target**: Set the minimum iOS deployment version to **11.0**.
*   **Swift Version**: Ensure your project is configured to use **Swift 5**.

### Android Configuration (Required)

Apply the following settings for Android support:

*   **SDK Version**: Set `compileSdkVersion` to **36**.
*   **Flutter Version**: Use **Flutter 3.44.0** or higher (required for built-in Kotlin support).
*   **MultiDex**: Ensure MultiDex is enabled in your project.

## 5. Additional Configurations (Optional)

### iOS Fullscreen Rotation

To support automatic screen rotation when entering fullscreen mode, add the following key to your `Info.plist` file:

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
   <string>UIInterfaceOrientationPortrait</string>
   <string>UIInterfaceOrientationLandscapeLeft</string>
   <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```
