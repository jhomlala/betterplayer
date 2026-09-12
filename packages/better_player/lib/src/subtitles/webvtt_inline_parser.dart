import 'package:material_ui/material_ui.dart';

class WebVttInlineParser {
  WebVttInlineParser._();

  static TextSpan parse(String rawText, TextStyle baseStyle) {
    // 1. Decode HTML entities
    final text = rawText
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', '\u00A0')
        .replaceAll('&lrm;', '\u200E')
        .replaceAll('&rlm;', '\u200F');

    return _parseSpans(text, baseStyle);
  }

  static TextSpan _parseSpans(String text, TextStyle currentStyle) {
    final children = <InlineSpan>[];
    final regex = RegExp(r'<([^>]+)>([^<]*)</\1>|<([^>]+)>|([^<]+)');
    final matches = regex.allMatches(text);

    var lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        children.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: currentStyle,
          ),
        );
      }

      // Case 1: Tag with body and closing tag e.g. <b>text</b>
      final fullTag = match.group(1);
      final body = match.group(2);
      // Case 2: Self-contained or opening tag e.g. <b.yellow> or timestamp <00:00:01.000>
      final singleTag = match.group(3);
      // Case 3: Plain text
      final plainText = match.group(4);

      if (fullTag != null && body != null) {
        final newStyle = _applyTagStyle(fullTag, currentStyle);
        children.add(_parseSpans(body, newStyle));
      } else if (singleTag != null) {
        // Check if it's a timestamp tag e.g. <00:00:01.000> or karaoke tag
        if (_isTimestampTag(singleTag)) {
          // Skip timestamp/karaoke tags entirely
        } else {
          // Might be voice tag like <v Speaker> or ignored tag
          // For <v Speaker>, we strip the tag and keep nothing or just keep body if handled.
          // Usually voice tags are <v Speaker>text</v> (matched by Case 1). If self-contained, ignore.
        }
      } else if (plainText != null) {
        children.add(TextSpan(text: plainText, style: currentStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      children.add(
        TextSpan(text: text.substring(lastIndex), style: currentStyle),
      );
    }

    return TextSpan(style: currentStyle, children: children);
  }

  static bool _isTimestampTag(String tag) {
    return RegExp(r'^\d{2}:\d{2}[\.:]\d{3}$').hasMatch(tag) ||
        RegExp(r'^\d+[\.:]\d{3}$').hasMatch(tag);
  }

  static TextStyle _applyTagStyle(String tag, TextStyle currentStyle) {
    final lowerTag = tag.toLowerCase().trim();
    if (lowerTag == 'b') {
      return currentStyle.copyWith(fontWeight: FontWeight.bold);
    }
    if (lowerTag == 'i') {
      return currentStyle.copyWith(fontStyle: FontStyle.italic);
    }
    if (lowerTag == 'u') {
      return currentStyle.copyWith(decoration: TextDecoration.underline);
    }
    if (lowerTag.startsWith('c.')) {
      final colorName = lowerTag.replaceFirst('c.', '');
      final color = _parseColor(colorName);
      if (color != null) {
        return currentStyle.copyWith(color: color);
      }
    }
    if (lowerTag.startsWith('lang ')) {
      return currentStyle;
    }
    return currentStyle;
  }

  static Color? _parseColor(String name) {
    switch (name) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'cyan':
        return Colors.cyan;
      case 'magenta':
        return Colors.purple;
      case 'lime':
        return Colors.lime;
      case 'maroon':
        return Colors.brown; // Approximation or custom color
      case 'navy':
        return Colors.indigo;
      case 'olive':
        return Colors.lime;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'silver':
        return Colors.grey;
      case 'aqua':
        return Colors.cyan;
      case 'fuchsia':
        return Colors.pink;
      default:
        return null;
    }
  }
}
