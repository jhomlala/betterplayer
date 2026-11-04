import 'package:better_player/src/configuration/player_translations.dart';
import 'package:material_ui/material_ui.dart';

/// Default error view displayed when a feed item fails to load or play.
class PlayerFeedErrorView extends StatelessWidget {
  /// Creates a default error view for feed items.
  const PlayerFeedErrorView({
    required this.onRetry,
    this.errorMessage,
    this.translations,
    super.key,
  });

  /// The error description to display, if any.
  final String? errorMessage;

  /// Callback executed when the retry button is pressed.
  final VoidCallback onRetry;

  /// Translations for error messages and action labels.
  final PlayerTranslations? translations;

  @override
  Widget build(BuildContext context) {
    final tr = translations ?? PlayerTranslations();
    final message = errorMessage ?? tr.feedDefaultError;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Semantics(
          identifier: 'better_player_feed_error_view',
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('feed_error_retry_button'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text(tr.feedRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
