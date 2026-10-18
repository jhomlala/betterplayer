import 'package:better_player/src/configuration/player_translations.dart';
import 'package:better_player/src/controls/player_about_link_row.dart';
import 'package:better_player/src/controls/player_about_logo.dart';
import 'package:better_player/src/core/player_about_constants.dart';
import 'package:material_ui/material_ui.dart';

/// Body of the About dialog. Both dialog variants use it.
class PlayerAboutContent extends StatelessWidget {
  const PlayerAboutContent({
    required this.translations,
    required this.isCupertino,
    super.key,
  });

  final PlayerTranslations translations;
  final bool isCupertino;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'better_player_about_dialog',
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlayerAboutLogo(),
          const SizedBox(height: 12),
          const Text(
            PlayerAboutConstants.poweredBy,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${translations.aboutVersion} ${PlayerAboutConstants.version}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              PlayerAboutLinkRow(
                url: PlayerAboutConstants.githubUrl,
                label: translations.aboutRepository,
                semanticsIdentifier: 'better_player_about_link_github',
                copiedLabel: translations.aboutLinkCopied,
                isCupertino: isCupertino,
              ),
              const Text(
                '|',
                style: TextStyle(color: Colors.white38),
              ),
              PlayerAboutLinkRow(
                url: PlayerAboutConstants.websiteUrl,
                label: translations.aboutHasoft,
                semanticsIdentifier: 'better_player_about_link_hasoft',
                copiedLabel: translations.aboutLinkCopied,
                isCupertino: isCupertino,
              ),
            ],
          ),
          PlayerAboutLinkRow(
            url: PlayerAboutConstants.issuesUrl,
            label: translations.aboutReportIssue,
            semanticsIdentifier: 'better_player_about_link_issues',
            copiedLabel: translations.aboutLinkCopied,
            isCupertino: isCupertino,
          ),
        ],
      ),
    );
  }
}
