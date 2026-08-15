# General Configuration

The `BetterPlayerConfiguration` class serves as the primary way to define the behavior and appearance of the player. This configuration object is passed to the `BetterPlayerController` during its initialization.

## Implementation Example

```dart
var betterPlayerConfiguration = BetterPlayerConfiguration(
    autoPlay: true,
    looping: true,
    fullScreenByDefault: true,
);
```

## Configuration Parameters

Below is a detailed list of available options within `BetterPlayerConfiguration`:

### Playback Options
*   **`autoPlay`**: Automatically start video playback once the widget is displayed.
*   **`startAt`**: Begin video playback at a specific timestamp.
*   **`looping`**: Determines if the video should restart automatically after finishing.
*   **`handleLifecycle`**: If enabled (default: true), automatically pauses the video when the app is minimized and resumes it when the app returns to the foreground.

### UI & Presentation
*   **`aspectRatio`**: The primary aspect ratio of the video player. This is crucial for correct layout.
*   **`fit`**: Defines how the video should be fitted within the player box (e.g., `BoxFit.contain`, `BoxFit.cover`).
*   **`placeholder`**: A widget displayed while the video is initializing or before playback starts.
*   **`showPlaceholderUntilPlay`**: Keep the placeholder visible until the play button is pressed.
*   **`placeholderOnTop`**: If true, the placeholder is placed on top of the video stack.
*   **`overlay`**: A widget placed between the video and the player controls.
*   **`showControlsOnInitialize`**: Determines if controls should be visible when the widget is first initialized.
*   **`expandToFill`**: If true, the player will expand to fill the available space.

### Fullscreen Management
*   **`fullScreenByDefault`**: Automatically enter fullscreen mode when playback begins.
*   **`allowedScreenSleep`**: Controls whether the device screen is allowed to sleep while in fullscreen mode.
*   **`fullScreenAspectRatio`**: The aspect ratio used specifically for fullscreen mode.
*   **`deviceOrientationsOnFullScreen`**: The set of allowed device orientations when entering fullscreen.
*   **`deviceOrientationsAfterFullScreen`**: The allowed device orientations after exiting fullscreen.
*   **`systemOverlaysAfterFullScreen`**: Defines which system overlays are visible after exiting fullscreen.
*   **`autoDetectFullscreenDeviceOrientation`**: If enabled, automatically determines the orientation based on the video's aspect ratio.
*   **`autoDetectFullscreenAspectRatio`**: Automatically determines the fullscreen aspect ratio.
*   **`routePageBuilder`**: A custom `RoutePageBuilder` for the fullscreen view.

### Advanced Features
*   **`subtitlesConfiguration`**: Defines the styling and behavior of subtitles.
*   **`controlsConfiguration`**: Deep customization of the player's UI controls.
*   **`rotation`**: Rotates the video box by a specific degree (0, 90, 180, 270).
*   **`translations`**: A list of `BetterPlayerTranslations` for localized UI strings.
*   **`eventListener`**: A callback function that receives all `BetterPlayerEvent` notifications.
*   **`playerVisibilityChangedBehavior`**: A callback to handle behavior changes based on player visibility.
*   **`autoDispose`**: If enabled (default: true), automatically disposes of the controller when the widget is destroyed.
*   **`useRootNavigator`**: Determines if the root navigator should be used for opening new pages (e.g., fullscreen).
