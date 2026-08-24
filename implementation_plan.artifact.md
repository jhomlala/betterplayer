# Android Maestro E2E Additional Flows

Implement additional Android Maestro E2E test flows that mirror the existing iOS test suite to improve platform parity.

## User Review Required

- No breaking changes.
- Implementing Android-specific versions of existing iOS E2E flows to ensure consistent coverage.

## Proposed Changes

### [Maestro]

#### [NEW] [android_hls_flow.yaml](file:///C:/Users/jhoml/betterplayer/maestro/android/android_hls_flow.yaml)
* Implement additional HLS-specific test cases for Android.

#### [NEW] [android_mp4_flow.yaml](file:///C:/Users/jhoml/betterplayer/maestro/android/android_mp4_flow.yaml)
* Implement MP4 test flows.

## Verification Plan

- Update the Android CI workflow if necessary.
- Run the new E2E tests locally on the Android emulator to verify they pass.
- Ensure all tests conform to Maestro and BetterPlayer E2E testing guidelines.
