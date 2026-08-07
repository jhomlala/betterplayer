# Update Gradle and AGP for Java 25 Compatibility

The project is currently using Gradle 8.7, which is incompatible with Java 25 (major version 69) used by the environment. This results in the `Unsupported class file major version 69` error. To fix this, we need to upgrade both Gradle and the Android Gradle Plugin (AGP) to versions that support Java 25.

## User Review Required

> [!IMPORTANT]
> Upgrading to Gradle 9.x and AGP 9.x is a major update. AGP 9.x introduces significant changes, including:
> - Minimum JDK 17 required (which you already have/exceed with Java 25).
> - Built-in Kotlin support (applying `kotlin-android` is still supported but AGP now manages KGP).
> - Removal of legacy DSL APIs.
> - Required SDK Build Tools 36.0.0+.

## Proposed Changes

### Gradle Wrapper
Update the Gradle wrapper to version 9.5.0 in both the plugin and the example app.

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/jhoml/betterplayer/android/gradle/wrapper/gradle-wrapper.properties)
#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/jhoml/betterplayer/example/android/gradle/wrapper/gradle-wrapper.properties)

### Android Gradle Plugin (AGP)
Update AGP to version 9.3.0 to ensure compatibility with Gradle 9.5.0 and Java 25.

#### [MODIFY] [build.gradle](file:///C:/Users/jhoml/betterplayer/android/build.gradle)
- Update AGP version from `8.3.0` to `9.3.0`.
- Update Kotlin version to `2.2.10` for better compatibility with AGP 9.x.

#### [MODIFY] [settings.gradle](file:///C:/Users/jhoml/betterplayer/example/android/settings.gradle)
- Update AGP version from `8.3.0` to `9.3.0`.
- Update Kotlin version to `2.2.10`.

## Verification Plan

### Automated Tests
- Run `flutter build apk` in the `example` directory to verify the build completes successfully.
- Check for any DSL deprecation warnings or errors during the build.

### Manual Verification
- Verify that the app still runs on a connected device/emulator.
