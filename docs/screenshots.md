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

## Recommended Screenshot Set

1. **Overview (Light & Dark, Desktop Wide)**:
   - Window size: 1280 x 800
   - Shows the live preview player, code snippet, category shortcuts, and featured cards.
2. **Streaming & Protocols (Desktop Wide)**:
   - Shows HLS, DASH, DRM, subtitle, and bitrate showcases with tag chips.
3. **Player Page (e.g. Subtitles or Custom Theme)**:
   - Shows active playback with custom control chrome and formatting.
4. **Mobile Layout (Light, Mobile Narrow)**:
   - Window size: 390 x 844
   - Shows bottom navigation bar and single-column demo cards.
