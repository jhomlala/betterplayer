## Translations configuration
You can provide translations for different languages with `BetterPlayerTranslations` class. You need to pass list of `BetterPlayerTranslations` to the `BetterPlayerConfiguration`. Here is an example:

```dart
 translations: [
              BetterPlayerTranslations(
                languageCode: "language_code for example pl",
                generalDefaultError: "translated text",
                generalNone: "translated text",
                generalDefault: "translated text",
                playlistLoadingNextVideo: "translated text",
                controlsLive: "translated text",
                controlsNextVideoIn: "translated text",
                overflowMenuPlaybackSpeed: "translated text",
                overflowMenuSubtitles: "translated text",
                overflowMenuQuality: "translated text",
              ),
              BetterPlayerTranslations(
                languageCode: "other language for example cz",
                generalDefaultError: "translated text",
                generalNone: "translated text",
                generalDefault: "translated text",
                playlistLoadingNextVideo: "translated text",
                controlsLive: "translated text",
                controlsNextVideoIn: "translated text",
                overflowMenuPlaybackSpeed: "translated text",
                overflowMenuSubtitles: "translated text",
                overflowMenuQuality: "translated text",
              ),
            ],
```
There are 8 pre build in languages: EN, PL, ZH (chinese simplified), HI (hindi), AR, TR, VI, ES. If you didn't provide
any translation then EN translations will be used or any of the pre build in translations, only if it's match current user locale.

You need to setup localizations in your app first to make it work. Here's how you can do that:
https://flutter.dev/docs/development/accessibility-and-localization/internationalization