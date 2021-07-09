import 'package:flutter/material.dart';

///Helper class for GestureDetector used within Better Player. Used to pass
///gestures to upper GestureDetectors.
class BetterPlayerMultipleGestureDetector extends InheritedWidget {
  final void Function()? onTap;
  final void Function()? onDoubleTap;
  final void Function()? onLongPress;

  const BetterPlayerMultipleGestureDetector({
    Key? key,
    required Widget child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  }) : super(key: key, child: child);

  static BetterPlayerMultipleGestureDetector? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        BetterPlayerMultipleGestureDetector>();
  }

  @override
  bool updateShouldNotify(BetterPlayerMultipleGestureDetector oldWidget) =>
      false;
}
