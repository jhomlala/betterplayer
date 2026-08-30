---
id: notification_configuration
title: Notification Configuration
---

# Notification Configuration

Better Player supports native platform notifications, allowing users to control playback from their device's lock screen or notification area.

| Android | iOS |
| :---: | :---: |
| ![Android Notification](https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/android_notification.png) | ![iOS Notification](https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/ios_notification.png) |

## Implementation

Notifications are configured using the `notificationConfiguration` parameter within the `PlayerDataSource`.

```dart
PlayerDataSource dataSource = PlayerDataSource(
    DataSourceType.network,
    Constants.elephantDreamVideoUrl,
    notificationConfiguration: NotificationConfiguration(
        showNotification: true,
        title: "Elephant's Dream",
        author: "Blender Foundation",
        imageUrl: "https://example.com/poster.jpg",
        activityName: "MainActivity", // Android only
    ),
);
```

## Configuration Parameters

*   **`showNotification`**: Enables or disables the notification feature.
*   **`title`**: The primary text displayed in the notification (e.g., video title).
*   **`author`**: The secondary text displayed in the notification (e.g., artist or channel).
*   **`imageUrl`**: The thumbnail image displayed in the notification (supports both network URLs and local files).
*   **`activityName`**: (Android only) The name of the activity to open when the notification is clicked.

## Advanced Considerations

### Background Playback
To allow playback to continue after the user leaves the application, ensure `handleLifecycle` is set to `false` in your `PlayerConfiguration`.

:::tip
Setting `handleLifecycle: false` is essential for audio-only apps or video apps that support background audio, as it prevents the system from automatically pausing playback when the app is minimized.
:::

### Custom Activity Name (Android)
By default, Better Player tries to launch the main activity when the notification is tapped. If your app has a specific entry point or you want to route the user to a specific screen, provide the `activityName` (e.g., `"com.your.package.MainActivity"`).
