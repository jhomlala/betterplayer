# Federated Plugin Migration Fixes

This plan addresses architectural "holes" in the current federated plugin structure of `betterplayer`, ensuring proper separation of concerns and removing platform-specific leakage from the core library and platform interface.

## User Review Required

> [!IMPORTANT]
> The refactoring moves platform-specific logic (like DASH support validation and PiP coordinate calculation) into the implementation packages. This ensures that the core `better_player` package remains platform-agnostic.

## Proposed Changes

### [Component] Platform Interface (`better_player_platform_interface`)
Clean up the platform interface to remove platform-specific UI leakage.

#### [MODIFY] [method_channel_video_player.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_platform_interface/lib/src/method_channel_video_player.dart)
- Remove `defaultTargetPlatform == TargetPlatform.iOS` check from `buildView`.
- Make `buildView` return a default `Texture` widget or throw `UnimplementedError` to force implementation in platform packages.

---

### [Component] Android Implementation (`better_player_android`)
Explicitly implement platform-specific behavior.

#### [MODIFY] [better_player_android.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_android/lib/better_player_android.dart)
- Override `buildView` to return the `Texture` widget.

---

### [Component] iOS Implementation (`better_player_ios`)
Explicitly implement platform-specific behavior and validations.

#### [MODIFY] [better_player_ios.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_ios/lib/better_player_ios.dart)
- Override `buildView` to return the `UiKitView`.
- Override `setDataSource` to validate against DASH streams (throwing an exception that the core controller will catch).

---

### [Component] Core Library (`better_player`)
Remove platform-specific logic and `dart:io` usage where possible.

#### [MODIFY] [better_player_controller.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/core/better_player_controller.dart)
- Remove hardcoded iOS DASH check in `setupDataSource`.
- Refactor `enablePictureInPicture` to remove `Platform.isAndroid` and `Platform.isIOS` checks.
- Delegate PiP coordinate calculation and platform-specific flows to the platform implementation.
- Handle `pipStart` event to trigger `enterFullScreen` for Android if necessary, keeping logic reactive rather than imperative.

#### [MODIFY] [video_player.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/video_player/video_player.dart)
- Ensure `VideoPlayerController` exposes the necessary platform abstractions for the refactored controller.

## Verification Plan

### Automated Tests
- Run `flutter test` in `packages/better_player` to ensure controller logic still works.
- Run `flutter test` in platform packages.

### Manual Verification
- Verify PiP works on both Android and iOS simulators.
- Verify DASH streams report an error correctly on iOS.
- Verify video rendering works on both platforms.
