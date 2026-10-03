import 'package:better_player/src/configuration/player_translations.dart';
import 'package:better_player/src/controls/player_cupertino_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';

class PlayerCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const PlayerCupertinoLocalizationsDelegate(this._translations);

  final PlayerTranslations _translations;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        PlayerCupertinoLocalizations(_translations),
      );

  @override
  bool shouldReload(PlayerCupertinoLocalizationsDelegate old) =>
      old._translations != _translations;
}
