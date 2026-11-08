# Tizen Architecture & Testing Guidelines (Experimental)

This document outlines the architecture, rendering pipeline, and CI/CD E2E testing strategy for the **EXPERIMENTAL** Tizen federated package (`packages/better_player_tizen`).

---

## Architecture: Dedicated Federated Package

Better Player uses a federated architecture. Tizen is implemented as an isolated experimental package: `packages/better_player_tizen`.

* **Status**: **EXPERIMENTAL**. Provides basic video playback only.
* **Engine**: Native Tizen Multimedia Player C API (`<player.h>`).
* **Rendering**: Decoded frames are captured via `player_set_media_packet_video_frame_decoded_cb` and copied into Flutter's compositor via `flutter::PixelBufferTexture` (`FlutterDesktopPixelBuffer`).
* **Zero blast radius**: Keeping `better_player_tizen` isolated guarantees zero regressions for Android, iOS, macOS, Windows, Linux, and Web workflows.

---

## E2E & CI Verification

* **NEVER Run E2E Tests Locally**: E2E integration tests run ONLY on CI/CD via GitHub Actions. Local verification is strictly for unit tests (`flutter test test`) and static analysis (`flutter analyze .`).
* **Unit Tests**: `packages/better_player_tizen/test/better_player_tizen_test.dart` and `test/src/player_tizen_controller_test.dart` test platform registration, texture creation, method channel calls, file path normalization, and video event streams.
* **Example E2E Tests**: `packages/better_player_tizen/example/test/example_e2e_test.dart` and `example/integration_test/tizen_flow_test.dart` verify full player lifecycle: play, pause, seek, volume, speed, looping, and disposal.
* **Screenshot Artifacts**: E2E test runs capture playback screenshots (`tizen_e2e_initialized.png`, `tizen_e2e_play.png`, `tizen_e2e_pause.png`, `tizen_e2e_seek.png`) and upload them to GitHub Actions as the `tizen-e2e-screenshots` artifact.
* **CI Workflow**: `.github/workflows/e2e_tizen.yml` runs on `ubuntu-22.04`, installs Tizen Studio CLI (`iot-headed-6.0`), `flutter-tizen`, pre-caches engine/embedder artifacts via GitHub REST API, runs unit and E2E tests, uploads screenshot artifacts, and compiles the native C++ plugin into a signed `.tpk` package.
