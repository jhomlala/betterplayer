import 'package:flutter/material.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final Function onTap;
  final bool disableSplashColor;

  const BetterPlayerMaterialClickableWidget({
    Key key,
    this.onTap,
    this.child,
    this.disableSplashColor = false,
  })  : assert(onTap != null),
        assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: disableSplashColor ? Colors.transparent : null,
        child: child,
        onTap: onTap,
      ),
    );
  }
}
