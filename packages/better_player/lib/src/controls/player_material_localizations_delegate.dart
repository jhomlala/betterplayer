import 'package:better_player/src/configuration/player_translations.dart';
import 'package:better_player/src/controls/player_material_localizations.dart';
import 'package:material_ui/material_ui.dart';

class PlayerMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const PlayerMaterialLocalizationsDelegate(this._translations);

  final PlayerTranslations _translations;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      PlayerMaterialLocalizations(_translations);

  @override
  bool shouldReload(PlayerMaterialLocalizationsDelegate old) =>
      old._translations != _translations;
}
