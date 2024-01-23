// Flutter imports:
import 'package:flutter/material.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final void Function() onTap;

  const BetterPlayerMaterialClickableWidget({
    required this.onTap, required this.child, Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(60),
      ),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
