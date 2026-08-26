# Federated Plugin Migration Improvements (1-5)

This plan covers the first five points identified for improving the federated plugin structure: deduplication of models/enums, harmonizing utilities, moving state representation to the platform interface, adding platform-specific tests, and standardizing analysis.

## User Review Required

> [!IMPORTANT]
> This refactor involves moving and renaming several core classes and enums. While I will update all internal references, external users of the library (if any) might be affected by these changes if they were relying on the specific names `BetterPlayerDataSourceType` or `BetterPlayerVideoFormat`.

## Proposed Changes

### 1. Model and Enum Deduplication

#### [MODIFY] [data_source_type.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_platform_interface/lib/src/models/data_source_type.dart)
Add `memory` to `DataSourceType`.

#### [DELETE] [better_player_data_source_type.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/configuration/better_player_data_source_type.dart)
Remove in favor of `DataSourceType` from PI.

#### [DELETE] [better_player_video_format.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/configuration/better_player_video_format.dart)
Remove in favor of `VideoFormat` from PI.

#### [MODIFY] [better_player_data_source.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/configuration/better_player_data_source.dart)
Update to use `DataSourceType` and `VideoFormat` from PI.

---

### 2. Harmonize BetterPlayerUtils

#### [MODIFY] [better_player_utils.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_platform_interface/lib/src/utils/better_player_utils.dart)
Ensure it is the single source of truth for logging.

#### [MODIFY] [better_player_utils.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/core/better_player_utils.dart) -> [NEW] [better_player_ui_utils.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/core/better_player_ui_utils.dart)
Rename to avoid collision and keep UI-related utilities separate.

---

### 3. Move State Representation to Platform Interface

#### [NEW] [video_player_value.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_platform_interface/lib/src/models/video_player_value.dart)
Move `VideoPlayerValue` here from the app package.

#### [MODIFY] [video_player.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player/lib/src/video_player/video_player.dart)
Remove `VideoPlayerValue` declaration and import it from PI.

---

### 4. Implement Platform-Specific Unit Tests

#### [NEW] [better_player_android_test.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_android/test/better_player_android_test.dart)
Test `BetterPlayerAndroid` implementation logic.

#### [NEW] [better_player_ios_test.dart](file:///C:/Users/jhoml/betterplayer/packages/better_player_ios/test/better_player_ios_test.dart)
Test `BetterPlayerIOS` implementation logic.

---

### 5. Standardize Linting and Analysis

#### [NEW] [analysis_options.yaml](file:///C:/Users/jhoml/betterplayer/packages/better_player_android/analysis_options.yaml)
#### [NEW] [analysis_options.yaml](file:///C:/Users/jhoml/betterplayer/packages/better_player_ios/analysis_options.yaml)
#### [NEW] [analysis_options.yaml](file:///C:/Users/jhoml/betterplayer/packages/better_player_platform_interface/analysis_options.yaml)

## Verification Plan

### Automated Tests
- Run `flutter test` in all modified packages:
  - `packages/better_player`
  - `packages/better_player_platform_interface`
  - `packages/better_player_android`
  - `packages/better_player_ios`
- Run `flutter analyze .` from the root to ensure no broken references.

### Manual Verification
- Run the `example` app to ensure video playback still works correctly across all types (Network, File, Memory).
