import 'package:better_player/src/configuration/player_translations.dart';
import 'package:better_player/src/controls/player_about_dialog.dart';
import 'package:better_player/src/core/player_about_constants.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('PlayerAboutDialog', () {
    Future<void> openDialog(
      WidgetTester tester, {
      required bool isCupertino,
      PlayerTranslations? translations,
      bool useCupertinoApp = false,
    }) async {
      final effectiveTranslations = translations ?? PlayerTranslations();
      final home = Builder(
        builder: (context) => GestureDetector(
          onTap: () {
            PlayerAboutDialog.show(
              context: context,
              translations: effectiveTranslations,
              isCupertino: isCupertino,
              useRootNavigator: false,
            );
          },
          child: const Text('open'),
        ),
      );

      final widget = useCupertinoApp
          ? CupertinoApp(home: home)
          : MaterialApp(
              theme: ThemeData(splashFactory: InkRipple.splashFactory),
              home: Scaffold(body: home),
            );

      await tester.pumpWidget(widget);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Material dialog displays texts, version, urls, and closes', (
      tester,
    ) async {
      await openDialog(tester, isCupertino: false);

      expect(find.byType(AlertDialog), findsOneWidget);
      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.backgroundColor, const Color(0xFF212121));
      expect(find.text(PlayerAboutConstants.poweredBy), findsOneWidget);
      expect(
        find.text('Version ${PlayerAboutConstants.version}'),
        findsOneWidget,
      );
      expect(find.text('Repository'), findsOneWidget);
      expect(find.text('Hasoft.pl'), findsOneWidget);
      expect(find.text('Report issue'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Cupertino dialog displays texts, version, urls, and closes', (
      tester,
    ) async {
      await openDialog(tester, isCupertino: true);

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      final cupertinoTheme = CupertinoTheme.of(
        tester.element(find.byType(CupertinoAlertDialog)),
      );
      expect(cupertinoTheme.brightness, Brightness.dark);
      expect(find.text(PlayerAboutConstants.poweredBy), findsOneWidget);
      expect(
        find.text('Version ${PlayerAboutConstants.version}'),
        findsOneWidget,
      );
      expect(find.text('Repository'), findsOneWidget);
      expect(find.text('Hasoft.pl'), findsOneWidget);
      expect(find.text('Report issue'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('Tapping URL copies to clipboard and resets Copied label', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<dynamic, dynamic>?;
            copied.add(args?['text'] as String);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await openDialog(tester, isCupertino: false);

      expect(find.text('Copied'), findsNothing);

      await tester.tap(find.text('Hasoft.pl'));
      await tester.pump();

      expect(copied, contains(PlayerAboutConstants.websiteUrl));
      expect(find.text('Copied'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.text('Copied'), findsNothing);
    });

    testWidgets('Polish translations show Wersja and Zamknij', (tester) async {
      await openDialog(
        tester,
        isCupertino: false,
        translations: PlayerTranslations.polish(),
      );

      expect(
        find.text('Wersja ${PlayerAboutConstants.version}'),
        findsOneWidget,
      );
      expect(find.text('Zamknij'), findsOneWidget);
    });

    testWidgets('CupertinoApp-only host opens dialog without error', (
      tester,
    ) async {
      await openDialog(
        tester,
        isCupertino: true,
        useCupertinoApp: true,
      );

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    });

    testWidgets(
      'Opens Material dialog without throwing when context lacks localizations',
      (tester) async {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (ctx, _, _) => builder(ctx),
            ),
            home: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  PlayerAboutDialog.show(
                    context: context,
                    translations: PlayerTranslations(),
                    isCupertino: false,
                    useRootNavigator: false,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'Opens Cupertino dialog without throwing when context lacks localizations',
      (tester) async {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (ctx, _, _) => builder(ctx),
            ),
            home: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  PlayerAboutDialog.show(
                    context: context,
                    translations: PlayerTranslations(),
                    isCupertino: true,
                    useRootNavigator: false,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byType(CupertinoAlertDialog), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(CupertinoAlertDialog), findsNothing);
      },
    );
  });
}
