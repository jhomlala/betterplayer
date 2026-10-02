import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'macos_datasource_swap_test.dart' as datasource_swap_test;
import 'macos_error_recovery_test.dart' as error_recovery_test;
import 'macos_ffi_test.dart' as ffi_test;
import 'macos_flow_test.dart' as flow_test;
import 'macos_hls_test.dart' as hls_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('macOS E2E Test Suite', () {
    group('Suite 1: Core Playback Flow', () {
      setUpAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] STARTING: Core Playback Flow\n'
          '========================================',
        );
      });
      tearDownAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] FINISHED: Core Playback Flow\n'
          '========================================',
        );
      });
      flow_test.main();
    });

    group('Suite 2: HLS Streaming', () {
      setUpAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] STARTING: HLS Streaming\n'
          '========================================',
        );
      });
      tearDownAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] FINISHED: HLS Streaming\n'
          '========================================',
        );
      });
      hls_test.main();
    });

    group('Suite 3: Data Source Swap & List Player', () {
      setUpAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] STARTING: Data Source Swap & List Player\n'
          '========================================',
        );
      });
      tearDownAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] FINISHED: Data Source Swap & List Player\n'
          '========================================',
        );
      });
      datasource_swap_test.main();
    });

    group('Suite 4: Error Recovery & Accurate Seek', () {
      setUpAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] STARTING: Error Recovery & Accurate Seek\n'
          '========================================',
        );
      });
      tearDownAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] FINISHED: Error Recovery & Accurate Seek\n'
          '========================================',
        );
      });
      error_recovery_test.main();
    });

    group('Suite 5: Native FFI API', () {
      setUpAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] STARTING: Native FFI API\n'
          '========================================',
        );
      });
      tearDownAll(() {
        debugPrint(
          '========================================\n'
          '  [E2E macOS] FINISHED: Native FFI API\n'
          '========================================',
        );
      });
      ffi_test.main();
    });
  });
}
