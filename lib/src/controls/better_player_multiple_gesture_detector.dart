import 'package:flutter/material.dart';

///Helper class for GestureDetector used within Better Player. Used to pass
///gestures to upper GestureDetectors.
class BetterPlayerMultipleGestureDetector extends InheritedWidget {
  const BetterPlayerMultipleGestureDetector({
    required super.child,
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });
  final void Function()? onTap;
  final void Function()? onDoubleTap;
  final void Function()? onLongPress;

  static BetterPlayerMultipleGestureDetector? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        BetterPlayerMultipleGestureDetector>();
  }

  @override
  bool updateShouldNotify(BetterPlayerMultipleGestureDetector oldWidget) =>
      false;
}
