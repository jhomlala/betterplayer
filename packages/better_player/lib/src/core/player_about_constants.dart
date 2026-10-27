/// Fixed values shown in the About dialog.
///
/// These values are not translatable on purpose.
class PlayerAboutConstants {
  const PlayerAboutConstants._();

  /// Must equal `version` in `pubspec.yaml`. A test checks this.
  static const String version = '1.30.0';

  static const String poweredBy = 'Powered by Better Player';
  static const String websiteUrl = 'https://hasoft.pl';
  static const String githubUrl = 'https://github.com/jhomlala/betterplayer';
  static const String issuesUrl =
      'https://github.com/jhomlala/betterplayer/issues';

  /// Never move or rename this file in the repository.
  static const String logoUrl =
      'https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/logo.png';
}
