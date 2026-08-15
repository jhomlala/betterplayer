# Notification Configuration

Better Player supports native platform notifications, allowing users to control playback from their device's lock screen or notification area.

<table align="center">
  <tr>
    <td><img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/android_notification.png"><br>Android</td>
    <td><img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/ios_notification.png"><br>iOS</td>
  </tr>
</table>

## Implementation

Notifications are configured using the `notificationConfiguration` parameter within the `BetterPlayerDataSource`.

```dart
BetterPlayerDataSource dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    Constants.elephantDreamVideoUrl,
    notificationConfiguration: BetterPlayerNotificationConfiguration(
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
To allow playback to continue after the user leaves the application, ensure `handleLifecycle` is set to `false` in your `BetterPlayerConfiguration`.

### Android Service Cleanup
On Android, we recommend implementing a service to ensure notifications are properly removed if the application is killed unexpectedly. Refer to the `BetterPlayerService` in the [Example Project](https://github.com/jhomlala/betterplayer/blob/feature/player_notifications/example/android/app/src/main/kotlin/com/jhomlala/example/BetterPlayerService.kt) for a reference implementation.
