import 'package:material_ui/material_ui.dart';

class BetterPlayerVideoAreaSemantics extends StatelessWidget {
  const BetterPlayerVideoAreaSemantics({
    required this.child,
    required this.semanticsIdentifier,
    super.key,
  });
  final Widget child;
  final String semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Video player',
      identifier: semanticsIdentifier,
      container: true,
      button: true,
      child: child,
    );
  }
}
