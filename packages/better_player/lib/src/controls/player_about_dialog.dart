import 'package:better_player/src/configuration/player_translations.dart';
import 'package:better_player/src/controls/player_about_content.dart';
import 'package:better_player/src/controls/player_cupertino_localizations_delegate.dart';
import 'package:better_player/src/controls/player_material_localizations_delegate.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Dialog with logo, version and project links.
class PlayerAboutDialog extends StatelessWidget {
  const PlayerAboutDialog({
    required this.translations,
    required this.isCupertino,
    super.key,
  });

  final PlayerTranslations translations;
  final bool isCupertino;

  /// Shows the dialog. Uses a Cupertino dialog when [isCupertino] is true.
  static Future<void> show({
    required BuildContext context,
    required PlayerTranslations translations,
    required bool isCupertino,
    required bool useRootNavigator,
  }) {
    final dialog = PlayerAboutDialog(
      translations: translations,
      isCupertino: isCupertino,
    );
    if (isCupertino) {
      final hasCupertino =
          Localizations.of<CupertinoLocalizations>(
            context,
            CupertinoLocalizations,
          ) !=
          null;
      if (hasCupertino) {
        return showCupertinoDialog<void>(
          context: context,
          useRootNavigator: useRootNavigator,
          barrierDismissible: true,
          builder: (_) => dialog,
        );
      }
    } else {
      final hasMaterial =
          Localizations.of<MaterialLocalizations>(
            context,
            MaterialLocalizations,
          ) !=
          null;
      if (hasMaterial) {
        return showDialog<void>(
          context: context,
          useRootNavigator: useRootNavigator,
          builder: (_) => dialog,
        );
      }
    }

    final themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(context, rootNavigator: useRootNavigator).context,
    );
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: true,
      barrierLabel: translations.aboutClose,
      barrierColor: Colors.black54,
      pageBuilder: (_, _, _) => themes.wrap(dialog),
      transitionDuration: const Duration(milliseconds: 150),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  static const Color _darkSurfaceColor = Color(0xFF212121);
  static const Color _darkAccentColor = Color(0xFF60A5FA);

  @override
  Widget build(BuildContext context) {
    final content = PlayerAboutContent(
      translations: translations,
      isCupertino: isCupertino,
    );
    final closeLabel = Text(translations.aboutClose);
    return Localizations.override(
      context: context,
      delegates: [
        PlayerMaterialLocalizationsDelegate(translations),
        PlayerCupertinoLocalizationsDelegate(translations),
      ],
      child: isCupertino
          ? CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.dark,
                primaryColor: _darkAccentColor,
              ),
              child: CupertinoAlertDialog(
                content: content,
                actions: [
                  Semantics(
                    identifier: 'better_player_about_close',
                    button: true,
                    child: CupertinoDialogAction(
                      onPressed: () => Navigator.of(context).pop(),
                      child: closeLabel,
                    ),
                  ),
                ],
              ),
            )
          : Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  surface: _darkSurfaceColor,
                  primary: _darkAccentColor,
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: _darkSurfaceColor,
                  surfaceTintColor: Colors.transparent,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: _darkAccentColor,
                    splashFactory: InkRipple.splashFactory,
                  ),
                ),
              ),
              child: AlertDialog(
                backgroundColor: _darkSurfaceColor,
                surfaceTintColor: Colors.transparent,
                content: content,
                actions: [
                  Semantics(
                    identifier: 'better_player_about_close',
                    button: true,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: closeLabel,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
