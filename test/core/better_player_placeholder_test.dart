import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/mock_method_channel.dart';

void main() {
  late BetterPlayerMockController mockController;

  setUp(() {
    final mockMethodChannel = MockMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        );

    mockController = BetterPlayerMockController(
      const BetterPlayerConfiguration(),
    );
  });

  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      home: Scaffold(
        body: widget,
      ),
    );
  }

  testWidgets('Placeholder shows widget from data source', (
    WidgetTester tester,
  ) async {
    const placeholder = Text('DataSource Placeholder');
    mockController.setupDataSource(
      BetterPlayerDataSource.network(
        'url',
        placeholder: placeholder,
      ),
    );

    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerPlaceholder(controller: mockController),
      ),
    );

    expect(find.text('DataSource Placeholder'), findsOneWidget);
  });

  testWidgets('Placeholder shows widget from configuration as fallback', (
    WidgetTester tester,
  ) async {
    const placeholder = Text('Config Placeholder');
    final controller = BetterPlayerMockController(
      const BetterPlayerConfiguration(placeholder: placeholder),
    );

    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerPlaceholder(controller: controller),
      ),
    );

    expect(find.text('Config Placeholder'), findsOneWidget);
  });

  testWidgets('Placeholder shows nothing when not provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerPlaceholder(controller: mockController),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
