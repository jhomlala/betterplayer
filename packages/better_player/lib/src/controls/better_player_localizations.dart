import 'package:better_player/src/configuration/player_translations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialLocalizations extends DefaultMaterialLocalizations {
  const BetterPlayerMaterialLocalizations(this._translations);

  final PlayerTranslations _translations;

  @override
  String get cancelButtonLabel => _translations.overflowMenuCancelLabel;

  @override
  String get scrimLabel => _translations.overflowMenuScrimLabel;

  @override
  String get bottomSheetLabel => _translations.overflowMenuScrimLabel;

  @override
  String scrimOnTapHint(String modalRouteContentName) =>
      'Close $modalRouteContentName';
}

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

class BetterPlayerCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const BetterPlayerCupertinoLocalizations(this._translations);

  final PlayerTranslations _translations;

  @override
  String get cancelButtonLabel => _translations.overflowMenuCancelLabel;

  @override
  String get modalBarrierDismissLabel => _translations.overflowMenuScrimLabel;
}

class BetterPlayerCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const BetterPlayerCupertinoLocalizationsDelegate(this._translations);

  final PlayerTranslations _translations;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async =>
      BetterPlayerCupertinoLocalizations(_translations);

  @override
  bool shouldReload(BetterPlayerCupertinoLocalizationsDelegate old) =>
      old._translations != _translations;
}
