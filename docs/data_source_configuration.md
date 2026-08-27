---
id: data_source_configuration
title: Data Source Configuration
---

# Data Source Configuration

The `PlayerDataSource` class defines all necessary information for a single video source within your application.

## Source Types

Better Player supports three primary source types:
1.  **Network**: Streams video from an external URL.
2.  **File**: Plays a video file stored locally on the device.
3.  **Memory**: Plays a video from a byte array.

### Factory Methods
We recommend using the provided factory methods for initialization:
*   `PlayerDataSource.network(url, ...)`
*   `PlayerDataSource.file(url, ...)`
*   `PlayerDataSource.memory(bytes, ...)`

## Configuration Parameters

### Core Parameters
*   **`type`**: The `PlayerDataSourceType` (Network, File, or Memory).
*   **`url`**: The path or URL of the video source.
*   **`subtitles`**: A list of `PlayerSubtitlesSource` objects.
*   **`headers`**: A map of custom HTTP headers for network requests.
*   **`bytes`**: The byte array for memory sources.

:::tip
When using `PlayerDataSource.memory`, providing a `videoExtension` (e.g., `"mp4"`) is highly recommended. It helps the underlying player engine correctly identify the media type when the byte stream is processed.

:::
### Adaptive Streaming (ASMS)
*   **`useAsmsSubtitles`**: Enables HLS/DASH manifest-based subtitles.
*   **`useAsmsTracks`**: Enables HLS/DASH manifest-based video tracks.
*   **`useAsmsAudioTracks`**: Enables HLS/DASH manifest-based audio tracks.
*   **`hlsTrackNames`**: Custom names for HLS tracks.

:::tip
You can programmatically control adaptive tracks. Use `controller.betterPlayerAsmsTracks` to retrieve available qualities and `controller.setTrack(track)` to force a specific one. For multi-language content, use `controller.betterPlayerAsmsAudioTracks` and `controller.setAudioTrack(audioTrack)`.

:::
### Features & Metadata
*   **`liveStream`**: Flag indicating the source is a live stream.
*   **`resolutions`**: Alternative resolutions for standard video files.
*   **`cacheConfiguration`**: Caching settings for network sources.
*   **`notificationConfiguration`**: Settings for native platform notifications.
*   **`overriddenDuration`**: A custom duration to return instead of the actual video length.
*   **`videoFormat`**: A hint for the video format (e.g., `.m3u8`, `.mp4`).
*   **`drmConfiguration`**: Digital Rights Management settings.
*   **`placeholder`**: A source-specific placeholder widget.
