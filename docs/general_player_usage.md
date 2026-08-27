---
id: general_player_usage
title: General Player Usage
---

# General Player Usage

This guide provides an overview of the core components and common patterns for using Better Player in your Flutter application.

## Quick Start Factory Methods

For rapid integration, Better Player offers simplified factory methods for common data source types. These methods are ideal for basic playback scenarios.

### Methods
*   `BetterPlayer.network(url, configuration)`: For streaming videos over a network.
*   `BetterPlayer.file(url, configuration)`: For playing local video files.

### Basic Implementation Example
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Simple Player"),
    ),
    body: AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer.network(
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        betterPlayerConfiguration: PlayerConfiguration(
          aspectRatio: 16 / 9,
        ),
      ),
    ),
  );
}
```

## Advanced Controller-Based Usage

For production applications, using `BetterPlayerController` is the recommended approach. This allows for deep customization and fine-grained control over the playback experience.

### Key Components

*   **PlayerDataSource**: Encapsulates all information regarding the media source, such as the URL, video format, subtitles, and headers.
*   **BetterPlayerController**: Manages the state and behavior of the player. It serves as the primary interface for interacting with the video engine.

### Implementation Workflow

#### 1. Controller Initialization
Initialize the controller and data source within your widget's `initState` to ensure proper lifecycle management:

```dart
late BetterPlayerController _betterPlayerController;

@override
void initState() {
  super.initState();
  
  PlayerDataSource betterPlayerDataSource = PlayerDataSource(
      PlayerDataSourceType.network,
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4");
      
  _betterPlayerController = BetterPlayerController(
      PlayerConfiguration(),
      betterPlayerDataSource: betterPlayerDataSource);
}
```

#### 2. Widget Integration
Display the player using the `BetterPlayer` widget, typically wrapped in an `AspectRatio` to maintain the desired dimensions:

```dart
@override
Widget build(BuildContext context) {
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: BetterPlayer(
      controller: _betterPlayerController,
    ),
  );
}
```

## Explore More
Better Player supports a wide range of advanced configurations, including playlists, DRM, and custom controls. Explore the subsequent sections of the documentation or the [Example Project](https://github.com/jhomlala/betterplayer/tree/master/example) for detailed implementation details.
