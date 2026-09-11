import 'package:better_player/src/configuration/player_translations.dart';
import 'package:better_player/src/controls/better_player_cupertino_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

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
