---
id: basic_usage
title: Basic Usage
---

# Basic Usage Guide

Better Player provides multiple ways to integrate video playback, ranging from quick setups to highly customizable implementations.

## Quick Start Methods

For simple use cases, you can use the static factory methods provided by the `BetterPlayer` class. These methods handle the basic configuration automatically, allowing you to display a video within seconds.

### Network Source
```dart
BetterPlayer.network(url, configuration)
```

### File Source
```dart
BetterPlayer.file(url, configuration)
```

### Implementation Example

The following example demonstrates how to display a video from a URL with a fixed 16:9 aspect ratio:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Basic Player Example"),
    ),
    body: AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer.network(
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        betterPlayerConfiguration: BetterPlayerConfiguration(
          aspectRatio: 16 / 9,
        ),
      ),
    ),
  );
}
```

## Standard Implementation

For advanced use cases requiring more granular control, you should manually create a `BetterPlayerDataSource` and a `BetterPlayerController`.

### Core Components

1.  **BetterPlayerDataSource**: Defines the source of the video, including the URL, source type, subtitle tracks, and additional metadata.
2.  **BetterPlayerController**: Acts as the central management hub for the player instance. It allows you to programmatically control playback (start, stop, seek), adjust volume, and monitor events.

### Step 1: Initialize the Controller

We recommend initializing the `BetterPlayerController` within the `initState` method of your `StatefulWidget`:

```dart
late BetterPlayerController _betterPlayerController;

@override
void initState() {
  super.initState();
  
  // Define the data source
  BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4");
  
  // Initialize the controller with the data source and configuration
  _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(),
      betterPlayerDataSource: betterPlayerDataSource);
}
```

### Step 2: Integrate the Widget

Wrap the `BetterPlayer` widget in an `AspectRatio` to ensure correct layout:

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

## Pro Tips

### Accessing the Controller via Context
In deep widget trees, you can access the `BetterPlayerController` from any descendant widget of `BetterPlayer` using the `InheritedWidget` pattern. This is useful for building custom UI overlays:

```dart
BetterPlayerController controller = BetterPlayerController.of(context);
```

### Source-Specific Placeholders
While you can define a global placeholder in `BetterPlayerConfiguration`, you can also provide a specific placeholder for each `BetterPlayerDataSource`. The source-specific placeholder will take precedence:

```dart
BetterPlayerDataSource(
  BetterPlayerDataSourceType.network,
  "url",
  placeholder: Image.asset("assets/video_thumbnail.png"),
)
```

## Advanced Examples

For more complex scenarios, such as playlists, caching, or custom controls, please refer to the [Example Project](https://github.com/jhomlala/betterplayer/tree/master/example).
