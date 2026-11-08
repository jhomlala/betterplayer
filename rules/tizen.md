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

* **Unit Tests**: `packages/better_player_tizen/test/better_player_tizen_test.dart` tests platform registration (`register` and `registerWith`), texture creation, method channel calls, and video event streams.
* **Example E2E Test**: `packages/better_player_tizen/example/test/example_e2e_test.dart` and `packages/better_player_tizen/example/integration_test/tizen_flow_test.dart` verify full player lifecycle, play, pause, seek, volume, speed, looping, and disposal.
* **CI Workflow**: `.github/workflows/e2e_tizen.yml` runs on `ubuntu-22.04`, installs Tizen Studio CLI (`iot-headed-6.0`), `flutter-tizen`, pre-caches engine/embedder artifacts via GitHub REST API, runs unit and E2E tests, and compiles the native C++ plugin into a signed `.tpk` package.
