Hi everyone,

Thank you for reporting this. I've investigated the current DRM implementation in Better Player.

We recently added support for configurable DRM security levels to specifically address Widevine L1 requirements on Android. You can now configure this in your `DrmConfiguration` when setting up your `PlayerDataSource`:

```dart
drmConfiguration: DrmConfiguration(
  drmType: DrmType.widevine,
  licenseUrl: 'YOUR_LICENSE_URL',
  drmSecurityLevel: DrmSecurityLevel.l1, // Explicitly requesting L1
),
```

**Why you might still be facing issues with L1 playback:**

1.  **Device Capability**: Widevine L1 is hardware-dependent. Please verify that your specific device actually supports Widevine L1. You can use an app like "DRM Info" from the Play Store to confirm this. If your device only supports L3, requesting L1 will cause the session to fail.
2.  **License Server Policy**: Even if your device supports L1, your content/license server may have policies that strictly require L1 for specific streams (e.g., HD/4K content). If the server detects any issue with the L1 request, it may deny the license.
3.  **Debug Logs**: If you are certain your device supports L1, please check your Android Logcat for errors from `DefaultDrmSessionManager` or `MediaDrm` when playback fails. This will show the exact reason why the session could not be established.

Given that the feature for L1 support is already implemented, I am closing this issue for now. If you are still encountering issues after verifying your device capabilities and checking the logs for specific `MediaDrm` error codes, please feel free to open a new issue with those specific details so we can investigate further.
