import 'package:better_player_cast/better_player_cast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('CastDevicePickerSheet', () {
    const config = CastConfiguration();
    const testDevice1 = CastDevice(
      id: 'tv-1',
      name: 'Living Room TV',
      host: '192.168.1.50',
      modelName: 'Chromecast Ultra',
    );
    const testDevice2 = CastDevice(
      id: 'tv-2',
      name: 'Bedroom TV',
      host: '192.168.1.51',
    );

    testWidgets('renders empty state when no devices found', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastDevicePickerSheet(
              configuration: config,
              devices: const [],
              isScanning: false,
              onDeviceSelected: (_) {},
              onDisconnect: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CastEmptyState), findsOneWidget);
      expect(find.text(config.noDevicesText), findsOneWidget);
      expect(
        find.bySemanticsLabel('Close'),
        findsOneWidget,
      );
    });

    testWidgets('renders scanning indicator when isScanning is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastDevicePickerSheet(
              configuration: config,
              devices: const [],
              isScanning: true,
              onDeviceSelected: (_) {},
              onDisconnect: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(config.scanningText), findsOneWidget);
    });

    testWidgets('renders list of discovered devices and triggers selection', (
      tester,
    ) async {
      CastDevice? selectedDevice;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastDevicePickerSheet(
              configuration: config,
              devices: const [testDevice1, testDevice2],
              isScanning: false,
              onDeviceSelected: (device) => selectedDevice = device,
              onDisconnect: () {},
            ),
          ),
        ),
      );

      expect(find.text('Living Room TV'), findsOneWidget);
      expect(find.text('Chromecast Ultra'), findsOneWidget);
      expect(find.text('Bedroom TV'), findsOneWidget);

      await tester.tap(find.text('Living Room TV'));
      await tester.pumpAndSettle();

      expect(selectedDevice, equals(testDevice1));
    });

    testWidgets('renders connected banner and triggers disconnect callback', (
      tester,
    ) async {
      var disconnectTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastDevicePickerSheet(
              configuration: config,
              devices: const [testDevice1],
              isScanning: false,
              connectedDevice: testDevice1,
              onDeviceSelected: (_) {},
              onDisconnect: () => disconnectTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byType(CastConnectedBanner), findsOneWidget);
      expect(find.text('Casting to'), findsOneWidget);
      expect(find.text(config.disconnectText), findsOneWidget);

      await tester.tap(find.text(config.disconnectText));
      await tester.pumpAndSettle();

      expect(disconnectTriggered, isTrue);
    });
  });
}
