import 'package:better_player/src/configuration/player_translations.dart';
import 'package:better_player/src/controls/better_player_material_localizations.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const BetterPlayerMaterialLocalizationsDelegate(this._translations);

  final PlayerTranslations _translations;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      BetterPlayerMaterialLocalizations(_translations);

  @override
  bool shouldReload(BetterPlayerMaterialLocalizationsDelegate old) =>
      old._translations != _translations;
}
