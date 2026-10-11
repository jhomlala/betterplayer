import 'package:better_player_example/main.dart';
import 'package:better_player_example/model/example_item.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WelcomePage Tests', () {
    testWidgets(
      'renders WelcomePage and switches tabs with semantics on wide screen',
      (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const BetterPlayerExample());
        await tester.pump();

        // Verify AppBar and Header
        expect(find.text('Better Player'), findsNWidgets(2));
        expect(find.text('Explore Categories'), findsOneWidget);

        // Verify theme popup menu button is present
        expect(find.byType(PopupMenuButton<ThemeMode>), findsOneWidget);

        // Switch to Core & UI tab via NavigationRailDestination
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text('Core & UI'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Basic player'), findsOneWidget);
        expect(find.text('Normal player'), findsOneWidget);

        // Switch to Streaming tab
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text('Streaming'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('HLS tracks'), findsOneWidget);
        expect(find.text('Subtitles & WebVTT'), findsOneWidget);

        // Switch to Advanced tab
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text('Advanced'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Playlist'), findsOneWidget);
        expect(find.text('Cache'), findsOneWidget);
      },
    );

    testWidgets('preserves semantics identifiers for Maestro tests', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const BetterPlayerExample());
      await tester.pump();

      // Go to Core & UI tab via NavigationRail
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Core & UI'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Basic player')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('renders mobile layout with NavigationBar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const BetterPlayerExample());
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    test('evaluates ExampleItem platform support correctly', () {
      const androidOnly = ExampleItem(
        title: 'Android Test',
        description: 'Test',
        icon: Icons.android,
        identifier: 'test_android',
        supportedPlatforms: {TargetPlatform.android},
        supportsWeb: false,
        pageBuilder: _dummyBuilder,
      );

      const allPlatforms = ExampleItem(
        title: 'All Platforms Test',
        description: 'Test',
        icon: Icons.star,
        identifier: 'test_all',
        pageBuilder: _dummyBuilder,
      );

      expect(allPlatforms.isSupportedOnCurrentPlatform, isTrue);
      expect(androidOnly.supportsWeb, isFalse);
    });

    testWidgets('renders PlatformNoteCard correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlatformNoteCard(
              title: 'Test Title',
              message: 'Test Message',
              isWarning: true,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });
  });
}

Widget _dummyBuilder(BuildContext context) => const SizedBox();
