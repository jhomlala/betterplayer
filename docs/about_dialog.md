---
id: about_dialog
title: About Dialog
---

# About Dialog

The 3-dots overflow menu includes an **About** option by default. It opens an adaptive dialog with the Better Player logo, the version, and links to hasoft.pl and GitHub.

## Overview

The dialog displays:
* The Better Player logo loaded from GitHub. When offline or unreachable, an icon fallback displays automatically.
* The "Powered by Better Player" attribution line.
* The active player version.
* Project and author links: tapping a link copies the address to the clipboard and shows "Copied" for two seconds.

## Translations

You can customize the dialog strings using `PlayerTranslations`:

```dart
PlayerTranslations(
  overflowMenuAbout: 'Info',
  aboutVersion: 'Release',
  aboutClose: 'Done',
  aboutLinkCopied: 'Copied!',
)
```

English and Polish translations are provided out of the box. Other locales default to English.

## Hiding the About Menu

Better Player core does not provide a public configuration flag to disable the About menu. Hiding it requires an enterprise license capability through Better Player Enterprise. See [Hide the About Menu](enterprise_hide_about.md).

## Limitations

* Setting `enableOverflowMenu: false` removes the entire 3-dots menu, including About.
* Supplying a `customControlsBuilder` replaces default player controls entirely.
* Loading the logo image requires network access to GitHub.
