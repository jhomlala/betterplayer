import 'package:better_player/src/configuration/player_translations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class BetterPlayerCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const BetterPlayerCupertinoLocalizations(this._translations);

  final PlayerTranslations _translations;

  @override
  String get cancelButtonLabel => _translations.overflowMenuCancelLabel;

  @override
  String get modalBarrierDismissLabel => _translations.overflowMenuScrimLabel;
}
