import 'package:material_ui/material_ui.dart';

/// Responsive wrapper that constrains demo content width on wide screens (Web, Desktop, Tablets)
/// while maintaining edge-to-edge layout on mobile phones.
class DemoContainer extends StatelessWidget {
  const DemoContainer({
    required this.child,
    super.key,
    this.maxWidth = 840,
    this.padding = EdgeInsets.zero,
  });

  /// The child content to display inside the constrained area.
  final Widget child;

  /// Maximum content width on wide viewports. Defaults to 840px.
  final double maxWidth;

  /// Optional padding around the content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
