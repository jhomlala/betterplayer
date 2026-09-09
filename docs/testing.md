---
id: testing
title: Testing
---

# Testing

When writing widget or integration tests for components that use Better Player, you need to account for its reliance on native platform implementations. By default, `BetterPlayerController` communicates with the native Android/iOS side via `BetterPlayerPlatform.instance`. In a standard Dart test environment, these native calls will fail.

To successfully test your UI, you should mock the underlying platform implementation.

## Mocking the Platform

The recommended approach is to mock the `BetterPlayerPlatform` instead of the `BetterPlayerController`. This allows you to use a real controller in your tests while safely bypassing the native dependencies.

### 1. Define a Mock Platform

Create a mock class that extends `BetterPlayerPlatform`. You only need to implement the methods that your tests will trigger.

```dart
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';

class MockBetterPlayerPlatform extends BetterPlayerPlatform {
  @override
  Future<int?> create({BufferingConfiguration? bufferingConfiguration}) async => 1;

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {}

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) => const Stream.empty();

  @override
  Widget buildView(int? textureId) => const SizedBox();

  @override
  Future<void> dispose(int? textureId) async {}
  
  @override
  Future<void> play(int? textureId) async {}
  
  @override
  Future<void> pause(int? textureId) async {}
  
  @override
  Future<void> setVolume(int? textureId, double volume) async {}
  
  @override
  Future<void> setLooping(int? textureId, bool looping) async {}
  
  @override
  Future<void> seekTo(int? textureId, Duration? position) async {}
  
  @override
  Future<Duration> getPosition(int? textureId) async => Duration.zero;
}
```

### 2. Configure the Mock in Tests

In your test's `setUp` method or at the beginning of your `testWidgets` call, replace the default platform instance with your mock.

```dart
void main() {
  setUp(() {
    // Replace the platform instance to prevent native errors
    BetterPlayerPlatform.instance = MockBetterPlayerPlatform();
  });

  testWidgets('MyPlayerWidget renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MyPlayerWidget(),
      ),
    ));

    expect(find.byType(BetterPlayer), findsOneWidget);
  });
}
```

## Why Mock the Platform?

Mocking the `BetterPlayerController` directly (e.g., using Mockito or Mocktail) is often problematic because the `BetterPlayer` widget and its internal components rely on the controller's internal state, streams, and configuration. 

By mocking the **Platform**, you:
*   Preserve all the library's internal logic and state management.
*   Only replace the specific layer that attempts to bridge to native code.
*   Avoid "stubbing" dozens of methods and getters in the controller.
