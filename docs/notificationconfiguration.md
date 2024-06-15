## Notification configuration
<table>
  <tr>
    <td>
	    <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/feature/player_notifications/media/android_notification.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/feature/player_notifications/media/ios_notification.png">
    </td>
    <td>
  </tr>
 </table>

To setup player notification use `notificationConfiguration` parameter in `BetterPlayerDataSource`.

```dart
BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
      notificationConfiguration: BetterPlayerNotificationConfiguration(
        showNotification: true,
        title: "Elephant dream",
        author: "Some author",
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/African_Bush_Elephant.jpg/1200px-African_Bush_Elephant.jpg",
        activityName: "MainActivity",
      ),
    );
```

There are 3 majors parameters here:
`title` - name of the resource, shown in first line;
`author` - author of the resource, shown in second line;
`imageUrl` - image of the resource (optional). Can be both link to external image or internal file;
`activityName` - name of activity used to open application back on notification click; used only for Activity;

If `showNotification` is set as true and no title and author is provided, then empty notification will be
displayed.

User can control the player with notification buttons (i.e. play/pause, seek). When notification feature
is used when there are more players at the same time, then last player will be used. Notification will
be shown after play for the first time.

To play resource after leaving the app, set `handleLifecycle` as false in your `BetterPlayerConfiguration`.

Important note for android:
You need to add special service in android native code. Service will simply destroy all remaining notifications. 
This service need to be used to handle situation when app is killed without proper player destroying. 
Check `BetterPlayerService` in example project to see how to add this service to your app.
https://github.com/jhomlala/betterplayer/blob/feature/player_notifications/example/android/app/src/main/kotlin/com/jhomlala/example/BetterPlayerService.kt

Here is an example of player with notification: https://github.com/jhomlala/betterplayer/blob/feature/player_notifications/example/lib/pages/notification_player_page.dart