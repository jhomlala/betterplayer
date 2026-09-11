import 'package:better_player/src/configuration/player_translations.dart';
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
      '${_translations.overflowMenuScrimHint} $modalRouteContentName';
}
