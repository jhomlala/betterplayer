import 'package:flutter/material.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final Function onTap;

  const BetterPlayerMaterialClickableWidget({Key key, this.onTap, this.child})
      : assert(onTap != null),
        assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        child: child,
        onTap: onTap,
      ),
    );
  }
}
