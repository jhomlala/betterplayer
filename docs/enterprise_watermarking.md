---
id: enterprise_watermarking
title: Dynamic Watermarking & Screen Shield
---

# Dynamic Watermarking & Screen Capture Protection

DRM stops direct stream ripping, but it cannot stop a viewer from pointing a phone camera at their screen or using capture tools on unprotected surfaces. Better Player Enterprise pairs dynamic forensic overlays with native OS screen capture guards to deter leaks and trace unauthorized recordings back to the source account.

---

## What It Does

* **Forensic Overlays**: Burns viewer-specific metadata (user ID, IP, email, session token, UTC timestamp, playhead position) directly over the video viewport.
* **Anti-Crop & Anti-OCR Motion**: Moves, bounces, jumps, or tiles the watermark with angled text and opacity pulsing so attackers cannot blur a fixed corner or strip text with standard rectangular OCR.
* **Native Screen Capture Blocking**: Activates OS-level window protection (`FLAG_SECURE` on Android, `.none` window sharing on macOS, `WDA_MONITOR` on Windows).
* **Active Recording Blackout (iOS)**: Detects screen recording and AirPlay mirroring in real time via `UIScreen.capturedDidChangeNotification`, automatically pausing playback and covering the video with a blackout shield until recording stops.
* **Tamper-Resistant Layering**: Renders inside the player's internal extension overlay slot above custom static overlays and below playback controls, with pointer events passed through so viewer controls keep working.

---

## License Setup

Screen capture protection and dynamic watermarking require an enterprise license with the `watermarking` capability. Initialize licensing at app startup:

```dart
import 'package:better_player_enterprise/better_player_enterprise.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BetterPlayerEnterprise.initialize(
    licenseId: 'YOUR_ENTERPRISE_LICENSE_KEY',
  );

  runApp(const MyApp());
}
```

> **Note:** Calling `controller.setScreenCaptureProtection(enabled: true)` directly without an authorized `PlayerSecurityExtension` and active enterprise license logs a warning and leaves protection disabled. If the license is missing or expired, the extension fails open so video playback continues uninterrupted.

---

## Quickstart

Create a `BetterPlayerWatermarkExtension` and pass it to `PlayerConfiguration.extensions`:

```dart
import 'package:better_player/better_player.dart';
import 'package:better_player_enterprise/better_player_enterprise.dart';
import 'package:flutter/material.dart';

final watermarkExtension = BetterPlayerWatermarkExtension(
  configuration: BetterPlayerWatermarkConfiguration(
    customData: const {
      'userId': 'usr_84920',
      'ip': '192.168.1.104',
    },
    textBuilder: (context) {
      final user = context.customData['userId'];
      final ip = context.customData['ip'];
      final pos = context.playbackPosition.inSeconds;
      return '$user • $ip • ${pos}s';
    },
    animationMode: BetterPlayerWatermarkAnimationMode.floatingDrift,
    screenCaptureMode: BetterPlayerScreenCaptureMode.blackoutOnCapture,
    minOpacity: 0.15,
    maxOpacity: 0.30,
    rotationDegrees: -15,
    updateInterval: const Duration(seconds: 5),
  ),
);

final controller = BetterPlayerController(
  PlayerConfiguration(
    aspectRatio: 16 / 9,
    autoPlay: true,
    extensions: [watermarkExtension],
  ),
  betterPlayerDataSource: PlayerDataSource(
    DataSourceType.network,
    'https://example.com/protected-stream.m3u8',
  ),
);
```

Render the player as usual with `BetterPlayer(controller: controller)`. The extension automatically injects the watermark overlay and activates the OS capture guard when attached.

---

## Animation Modes

Choose how the watermark moves across the video viewport using `BetterPlayerWatermarkAnimationMode`:

| Mode | Behavior |
|---|---|
| `floatingDrift` | Continuous smooth vector bounce across the viewport bounds. |
| `randomJump` | Jumps to pseudo-random coordinates every `updateInterval` with cross-fade transitions. |
| `edgeBounce` | Glides along the outer perimeter of the video viewport. |
| `tiledGrid` | Repeats faint, angled micro-stamps across the entire video surface. |
| `staticPosition` | Stays at a fixed coordinate with optional opacity pulsing between `minOpacity` and `maxOpacity`. |

---

## Screen Capture Protection Modes

Configure how the player handles OS screenshots and screen recordings with `BetterPlayerScreenCaptureMode`:

| Mode | Behavior |
|---|---|
| `disabled` | No OS screen capture protection. Only the visual watermark renders. |
| `protectSurface` | Enables native OS window protection to black out screenshots and recordings. |
| `blackoutOnCapture` | Enables native OS window protection **and** listens to `controller.screenCaptureStream`. When active capture is detected (such as iOS screen recording), pauses the video and covers the viewport with a blackout shield. |

### Platform Behavior

| Platform | Native Mechanism | Result on Screenshot / Recording |
|---|---|---|
| **Android** | `WindowManager.LayoutParams.FLAG_SECURE` | OS blocks screenshots and records a black window. |
| **macOS** | `NSWindow.sharingType = .none` | Window is excluded from screenshots and screen sharing. |
| **Windows** | `SetWindowDisplayAffinity(hwnd, WDA_MONITOR)` | OS compositor blacks out the window in capture tools. |
| **iOS** | `UIScreen.isCaptured` + `capturedDidChangeNotification` | Emits capture state via `screenCaptureStream`; `blackoutOnCapture` pauses playback and blanks the player. |

---

## Updating Watermarks at Runtime

You can change the watermark text, animation mode, or capture policy mid-stream without recreating the controller:

```dart
watermarkExtension.updateConfiguration(
  BetterPlayerWatermarkConfiguration(
    text: 'CONFIDENTIAL • Do Not Distribute',
    animationMode: BetterPlayerWatermarkAnimationMode.tiledGrid,
    screenCaptureMode: BetterPlayerScreenCaptureMode.protectSurface,
  ),
);
```

---

## Configuration Reference

### `BetterPlayerWatermarkConfiguration`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `text` | `String?` | `null` | Static watermark text when dynamic formatting is not needed. Either `text` or `textBuilder` is required. |
| `textBuilder` | `BetterPlayerWatermarkTextBuilder?` | `null` | Callback resolving dynamic text from `BetterPlayerWatermarkContext` (`playbackPosition`, `systemTime`, `videoDuration`, `customData`). |
| `animationMode` | `BetterPlayerWatermarkAnimationMode` | `randomJump` | Motion and positioning strategy across the viewport. |
| `screenCaptureMode` | `BetterPlayerScreenCaptureMode` | `protectSurface` | OS screen capture and recording guard policy. |
| `style` | `TextStyle` | `14px bold white + shadow` | Font size, color, weight, and drop shadow for the watermark text. |
| `minOpacity` | `double` | `0.12` | Minimum opacity floor (`0.0` to `1.0`) during transitions or pulsing. |
| `maxOpacity` | `double` | `0.30` | Maximum opacity ceiling (`0.0` to `1.0`). |
| `rotationDegrees` | `double` | `-15.0` | Text rotation angle in degrees to defeat rectangular OCR. |
| `updateInterval` | `Duration` | `8 seconds` | Interval between coordinate jumps and `textBuilder` refreshes. |
| `customData` | `Map<String, dynamic>` | `const {}` | Arbitrary metadata forwarded to `context.customData` inside `textBuilder`. |
| `enabled` | `bool` | `true` | Toggles the watermark overlay on or off. |

---

## Requesting the Capability

To obtain an enterprise license with the `watermarking` capability, contact **[betterplayer@hasoft.pl](mailto:betterplayer@hasoft.pl)**.
