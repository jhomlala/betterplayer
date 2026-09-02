import 'package:material_ui/material_ui.dart';


/// Widget for displaying closed captions on top of a video.
///
/// If [text] is null, this widget will not display anything.
///
/// If [textStyle] is supplied, it will be used to style the text in the closed
/// caption.
///
/// Note: in order to have closed captions, you need to specify a
/// [VideoPlayerController.closedCaptionFile].
///
/// Usage:
///
/// ```dart
/// Stack(children: <Widget>[
///   VideoPlayer(_controller),
///   ClosedCaption(text: _controller.value.caption.text),
/// ]),
/// ```
class ClosedCaption extends StatelessWidget {
  /// Creates a a new closed caption, designed to be used with
  /// [VideoPlayerValue.caption].
  ///
  /// If [text] is null, nothing will be displayed.
  const ClosedCaption({super.key, this.text, this.textStyle});

  /// The text that will be shown in the closed caption, or null if no caption
  /// should be shown.
  final String? text;

  /// Specifies how the text in the closed caption should look.
  ///
  /// If null, defaults to [DefaultTextStyle.of(context).style] with size 36
  /// font colored white.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ??
        DefaultTextStyle.of(
          context,
        ).style.copyWith(fontSize: 36, color: Colors.white);

    if (text == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB8000000),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(text!, style: effectiveTextStyle),
          ),
        ),
      ),
    );
  }
}
