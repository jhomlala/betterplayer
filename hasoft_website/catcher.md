---
layout: default
title: Catcher
---

# Catcher

**Automated error catching and handling for Flutter.**

Catcher automatically catches unchecked errors, generates reports, and handles them according to your configuration. Inspired by ACRA for Android.

## 🚀 Key Features
* **Multi-Platform**: Works on Android, iOS, Web, and Desktop.
* **Device Info**: Automatically collects hardware and OS details.
* **Report Modes**: Silent, Notification, Dialog, or dedicated Page.
* **Handlers**: Console, Email, Http, Sentry, Slack, Discord, and more.
* **Profiles**: Different configurations for debug and release.

## 📦 Quick Start

Add to `pubspec.yaml`:
```yaml
dependencies:
  catcher: ^latest_version
```

Basic usage:
```dart
void main() {
  CatcherOptions debugOptions = CatcherOptions(DialogReportMode(), [ConsoleHandler()]);
  CatcherOptions releaseOptions = CatcherOptions(PageReportMode(), [EmailHandler(["support@hasoft.pl"])]);

  Catcher(rootWidget: MyApp(), debugConfig: debugOptions, releaseConfig: releaseOptions);
}
```

## 📖 Links
* [Pub.dev](https://pub.dev/packages/catcher)
* [GitHub Repository](https://github.com/jhomlala/catcher)
