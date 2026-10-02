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
    flow_test.main();
    hls_test.main();
    datasource_swap_test.main();
    error_recovery_test.main();
    ffi_test.main();
  });
}
