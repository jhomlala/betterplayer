# Data Source Configuration

The `BetterPlayerDataSource` class defines all necessary information for a single video source within your application.

## Source Types

Better Player supports three primary source types:
1.  **Network**: Streams video from an external URL.
2.  **File**: Plays a video file stored locally on the device.
3.  **Memory**: Plays a video from a byte array.

### Factory Methods
We recommend using the provided factory methods for initialization:
*   `BetterPlayerDataSource.network(url, ...)`
*   `BetterPlayerDataSource.file(url, ...)`
*   `BetterPlayerDataSource.memory(bytes, ...)`

## Configuration Parameters

### Core Parameters
*   **`type`**: The `BetterPlayerDataSourceType` (Network, File, or Memory).
*   **`url`**: The path or URL of the video source.
*   **`subtitles`**: A list of `BetterPlayerSubtitlesSource` objects.
*   **`headers`**: A map of custom HTTP headers for network requests.
*   **`bytes`**: The byte array for memory sources.

### Adaptive Streaming (ASMS)
*   **`useAsmsSubtitles`**: Enables HLS/DASH manifest-based subtitles.
*   **`useAsmsTracks`**: Enables HLS/DASH manifest-based video tracks.
*   **`useAsmsAudioTracks`**: Enables HLS/DASH manifest-based audio tracks.
*   **`hlsTrackNames`**: Custom names for HLS tracks.

### Features & Metadata
*   **`liveStream`**: Flag indicating the source is a live stream.
*   **`resolutions`**: Alternative resolutions for standard video files.
*   **`cacheConfiguration`**: Caching settings for network sources.
*   **`notificationConfiguration`**: Settings for native platform notifications.
*   **`overriddenDuration`**: A custom duration to return instead of the actual video length.
*   **`videoFormat`**: A hint for the video format (e.g., `.m3u8`, `.mp4`).
*   **`drmConfiguration`**: Digital Rights Management settings.
*   **`placeholder`**: A source-specific placeholder widget.
