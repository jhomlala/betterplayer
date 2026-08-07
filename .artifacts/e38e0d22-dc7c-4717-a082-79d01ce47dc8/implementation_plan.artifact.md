# Migrate ExoPlayer to Media3

Migrate the `betterplayer` Android plugin from standalone ExoPlayer 2.17.1 to AndroidX Media3 1.1.1.

## User Review Required

> [!IMPORTANT]
> This migration involves changing the underlying media playback engine to Media3. While Media3 is the successor to ExoPlayer 2, some internal APIs have changed.
> `MediaSessionConnector` and `MediaSessionCompat` will be replaced by the native Media3 `MediaSession`.

## Proposed Changes

### Android Build Configuration

#### [MODIFY] [build.gradle](file:///C:/Users/jhoml/betterplayer/android/build.gradle)
- Update `compileSdkVersion` to 33.
- Replace all `com.google.android.exoplayer` dependencies with their `androidx.media3` equivalents.
- Add `androidx.media3:media3-session` dependency.

### Kotlin Source Code

#### [MODIFY] [BetterPlayer.kt](file:///C:/Users/jhoml/betterplayer/android/src/main/kotlin/com/jhomlala/better_player/BetterPlayer.kt)
- Update all ExoPlayer imports to Media3.
- Replace `MediaSessionCompat` and `MediaSessionConnector` with `androidx.media3.session.MediaSession`.
- Update `PlayerNotificationManager` usage or migrate to `MediaSessionService` if applicable (BetterPlayer seems to manage its own notification).

#### [MODIFY] [BetterPlayerCache.kt](file:///C:/Users/jhoml/betterplayer/android/src/main/kotlin/com/jhomlala/better_player/BetterPlayerCache.kt)
- Update imports for `SimpleCache`, `LeastRecentlyUsedCacheEvictor`, and `ExoDatabaseProvider`.

#### [MODIFY] [CacheDataSourceFactory.kt](file:///C:/Users/jhoml/betterplayer/android/src/main/kotlin/com/jhomlala/better_player/CacheDataSourceFactory.kt)
- Update imports for `DataSource`, `CacheDataSource`, etc.

#### [MODIFY] [CacheWorker.kt](file:///C:/Users/jhoml/betterplayer/android/src/main/kotlin/com/jhomlala/better_player/CacheWorker.kt)
- Update imports for `CacheWriter`, `DataSpec`, etc.

#### [MODIFY] [CustomDefaultLoadControl.kt](file:///C:/Users/jhoml/betterplayer/android/src/main/kotlin/com/jhomlala/better_player/CustomDefaultLoadControl.kt)
- Update imports for `DefaultLoadControl`.

#### [MODIFY] [DataSourceUtils.kt](file:///C:/Users/jhoml/betterplayer/android/src/main/kotlin/com/jhomlala/better_player/DataSourceUtils.kt)
- Update imports for `DataSource`, `DefaultHttpDataSource`.

## Verification Plan

### Automated Tests
- Run `./gradlew build` in the `android` directory.

### Manual Verification
- Run the example app and verify:
    - Video playback (HLS, DASH, Progressive).
    - Playback controls (Play/Pause, Seek).
    - Notification display and controls.
    - Cache functionality.
