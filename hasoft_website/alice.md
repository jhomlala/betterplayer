---
layout: default
title: Alice
---

# Alice

**HTTP Inspector tool for Flutter.**

Alice catches and stores HTTP requests and responses, allowing them to be viewed through a simple and intuitive user interface. Inspired by Chuck and Chucker.

## 🚀 Key Features
* **Detailed Logs**: View headers, body, status codes, and timing.
* **Inspector UI**: Built-in interface to browse traffic within the app.
* **Shake to Open**: Conveniently open the UI with a physical shake.
* **Client Support**: Compatible with Dio, HttpClient, Http, and Chopper.
* **Export Logs**: Save logs to a file for external review.

## 📦 Quick Start

Add to `pubspec.yaml`:
```yaml
dependencies:
  alice: ^latest_version
```

Configuration:
```dart
final navigatorKey = GlobalKey<NavigatorState>();
Alice alice = Alice(navigatorKey: navigatorKey);

// In MaterialApp
MaterialApp(
  navigatorKey: navigatorKey,
  home: YourWidget(),
)

// Add interceptor to Dio
dio.interceptors.add(alice.getDioInterceptor());
```

## 📖 Links
* [Pub.dev](https://pub.dev/packages/alice)
* [GitHub Repository](https://github.com/jhomlala/alice)
