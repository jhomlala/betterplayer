import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder findById(String id) {
  return find.byWidgetPredicate(
    (widget) =>
        (widget is Semantics &&
            (widget.properties.identifier == id ||
                widget.properties.label == id)) ||
        (widget is Text && widget.data == id),
    description: 'Widget with identifier or text "$id"',
  );
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration pollInterval = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(pollInterval);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget);
}

Future<void> pumpUntilNotFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration pollInterval = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(pollInterval);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  expect(finder, findsNothing);
}

Future<void> waitModalClosed(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(BottomSheet).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
      return;
    }
  }
}

Future<void> tapWhenReady(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilFound(tester, finder, timeout: timeout);
  try {
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 200));
  } catch (_) {}
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> scrollAndTap(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) {
      try {
        await tester.ensureVisible(finder.first);
        await tester.pump(const Duration(milliseconds: 200));
      } catch (_) {}
      await tester.tap(finder.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      return;
    }
    final scrollables = find.byType(Scrollable);
    final targetScrollable =
        scrollable ??
        (scrollables.evaluate().length > 1
            ? scrollables.last
            : scrollables.first);
    await tester.drag(targetScrollable, const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(finder, findsOneWidget);
}
