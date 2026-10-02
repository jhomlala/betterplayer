import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'windows_datasource_swap_test.dart' as datasource_swap_test;
import 'windows_error_recovery_test.dart' as error_recovery_test;
import 'windows_ffi_test.dart' as ffi_test;
import 'windows_flow_test.dart' as flow_test;
import 'windows_hls_test.dart' as hls_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Windows E2E Test Suite', () {
    flow_test.main();
    hls_test.main();
    datasource_swap_test.main();
    error_recovery_test.main();
    ffi_test.main();
  });
}
