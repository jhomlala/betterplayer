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
      return showCupertinoDialog<void>(
        context: context,
        useRootNavigator: useRootNavigator,
        barrierDismissible: true,
        builder: (_) => dialog,
      );
    }
    return showDialog<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (_) => dialog,
    );
  }

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
          ? CupertinoAlertDialog(
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
            )
          : AlertDialog(
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
    );
  }
}
