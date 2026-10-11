# Example App Screenshots Guide

Instructions for capturing clean, consistent screenshots of the Better Player example app for docs and READMEs.

## Window Dimensions

| Target | Logical Size | Purpose |
|---|---|---|
| **Desktop Wide** | 1280 x 800 | Full UI showcase with NavigationRail, hero player, and two-column grids |
| **Mobile Narrow** | 390 x 844 | Phone layout with bottom NavigationBar and stacked cards |

## Running the App

Run the example app on desktop or web:

```bash
cd packages/better_player_example
flutter run -d windows
```

On macOS or Linux:

```bash
flutter run -d macos
```

## Theme Switching

Switch between Light and Dark mode using the theme icon in the top right corner of the AppBar.

## Active Screenshot Assets

All screenshots are stored under `docs/assets/screenshots/`:

| File | Platform | Viewport | Content |
|---|---|---|---|
| `web_01_overview_dark.png` | Web / Desktop | 1280 x 800 (Dark) | Overview tab with live hero player, code snippet, category shortcuts, and featured cards |
| `web_02_overview_light.png` | Web / Desktop | 1280 x 800 (Light) | Overview tab in Light mode |
| `web_03_streaming.png` | Web / Desktop | 1280 x 800 | Streaming & Protocols tab with HLS, DASH, DRM, and ClearKey feature badges |
| `web_04_subtitles.png` | Web / Desktop | 1280 x 800 | Advanced WebVTT styled subtitles with alignment and formatting tags |
| `web_05_hls_tracks.png` | Web / Desktop | 1280 x 800 | HLS Track & Quality switching with the Auto quality menu open |
| `android_01_overview.png` | Android | ~390 x 844 | Mobile Overview tab with compact top bar and bottom NavigationBar |
| `android_02_core.png` | Android | ~390 x 844 | Core & UI category list on mobile |
| `android_03_player.png` | Android | ~390 x 844 | Basic Player portrait demo with default controls |
| `android_04_fullscreen.png` | Android | Landscape | Mobile fullscreen playback with touch controls and scrubbing |
| `android_05_pip.png` | Android | Home Screen | Native floating Picture-in-Picture window over launcher |
