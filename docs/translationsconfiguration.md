# Internationalization & Translations

Better Player allows you to localize all UI strings using the `BetterPlayerTranslations` class.

## Built-in Languages

Better Player includes pre-built translations for the following languages:
*   English (EN) - **Default**
*   Polish (PL)
*   Chinese Simplified (ZH)
*   Hindi (HI)
*   Arabic (AR)
*   Turkish (TR)
*   Vietnamese (VI)
*   Spanish (ES)

The player automatically selects the appropriate translation if it matches the current user's locale.

## Custom Translations

You can provide your own translations by passing a list of `BetterPlayerTranslations` to the `BetterPlayerConfiguration`.

```dart
BetterPlayerConfiguration(
    translations: [
      BetterPlayerTranslations(
        languageCode: "fr",
        generalDefaultError: "Une erreur est survenue",
        generalNone: "Aucun",
        generalDefault: "Défaut",
        playlistLoadingNextVideo: "Chargement de la vidéo suivante...",
        controlsLive: "EN DIRECT",
        controlsNextVideoIn: "Vidéo suivante dans",
        overflowMenuPlaybackSpeed: "Vitesse de lecture",
        overflowMenuSubtitles: "Sous-titres",
        overflowMenuQuality: "Qualité",
      ),
    ],
);
```

## Setup Requirements
To ensure translations function correctly, you must first configure internationalization within your Flutter application. Refer to the [Flutter Localization Guide](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization) for more information.
