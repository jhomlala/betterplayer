import 'package:material_ui/material_ui.dart';

enum WebVttCueAlignment { start, center, end, left, right }

extension WebVttCueAlignmentX on WebVttCueAlignment {
  TextAlign toTextAlign() {
    switch (this) {
      case WebVttCueAlignment.start:
      case WebVttCueAlignment.left:
        return TextAlign.left;
      case WebVttCueAlignment.center:
        return TextAlign.center;
      case WebVttCueAlignment.end:
      case WebVttCueAlignment.right:
        return TextAlign.right;
    }
  }

  Alignment toAlignment() {
    switch (this) {
      case WebVttCueAlignment.start:
      case WebVttCueAlignment.left:
        return Alignment.bottomLeft;
      case WebVttCueAlignment.center:
        return Alignment.bottomCenter;
      case WebVttCueAlignment.end:
      case WebVttCueAlignment.right:
        return Alignment.bottomRight;
    }
  }
}
