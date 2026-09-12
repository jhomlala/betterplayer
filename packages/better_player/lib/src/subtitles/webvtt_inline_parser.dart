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

    return _parseStack(text, baseStyle);
  }

  static TextSpan _parseStack(String text, TextStyle baseStyle) {
    final styleStack = <TextStyle>[baseStyle];
    final children = <InlineSpan>[];

    // Tokenize tags and text: matches <tag> or plain text
    final regex = RegExp('(<[^>]+>)|([^<]+)');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      final tag = match.group(1);
      final plainText = match.group(2);

      if (tag != null) {
        if (tag.startsWith('</')) {
          // Closing tag
          if (styleStack.length > 1) {
            styleStack.removeLast();
          }
        } else if (tag.endsWith('/>') || tag == '<br>' || tag == '<br/>') {
          // Self-closing or break tag
          if (tag.toLowerCase().contains('br')) {
            children.add(TextSpan(text: '\n', style: styleStack.last));
          }
        } else {
          // Opening tag
          if (_isTimestampTag(tag.substring(1, tag.length - 1))) {
            // Ignore timestamp tags
          } else {
            final newStyle = _applyTagStyle(tag, styleStack.last);
            styleStack.add(newStyle);
          }
        }
      } else if (plainText != null) {
        children.add(TextSpan(text: plainText, style: styleStack.last));
      }
    }

    return TextSpan(style: baseStyle, children: children);
  }

  static bool _isTimestampTag(String tag) {
    final cleaned = tag.trim();
    return RegExp(r'^\d{2}:\d{2}[\.:]\d{3}$').hasMatch(cleaned) ||
        RegExp(r'^\d+[\.:]\d{3}$').hasMatch(cleaned);
  }

  static TextStyle _applyTagStyle(String fullTag, TextStyle currentStyle) {
    final inner = fullTag.substring(1, fullTag.length - 1).trim();
    final lowerTag = inner.toLowerCase();

    if (lowerTag == 'b' || lowerTag.startsWith('b ')) {
      return currentStyle.copyWith(fontWeight: FontWeight.bold);
    }
    if (lowerTag == 'i' || lowerTag.startsWith('i ')) {
      return currentStyle.copyWith(fontStyle: FontStyle.italic);
    }
    if (lowerTag == 'u' || lowerTag.startsWith('u ')) {
      return currentStyle.copyWith(decoration: TextDecoration.underline);
    }
    if (lowerTag.startsWith('c.')) {
      final colorName = lowerTag.replaceFirst('c.', '');
      final color = _parseColor(colorName);
      if (color != null) {
        return currentStyle.copyWith(color: color);
      }
    }
    if (lowerTag.startsWith('font')) {
      return _parseFontTag(inner, currentStyle);
    }
    return currentStyle;
  }

  static TextStyle _parseFontTag(String tagContent, TextStyle currentStyle) {
    var style = currentStyle;
    final colorRegex = RegExp(
      r'color\s*=\s*["\x27]?([^"\x27\s>]+)["\x27]?',
      caseSensitive: false,
    );
    final match = colorRegex.firstMatch(tagContent);
    if (match != null) {
      final colorValue = match.group(1);
      if (colorValue != null) {
        final color = _parseColorValue(colorValue);
        if (color != null) {
          style = style.copyWith(color: color);
        }
      }
    }
    return style;
  }

  static Color? _parseColorValue(String value) {
    if (value.startsWith('#')) {
      try {
        var hex = value.replaceFirst('#', '');
        if (hex.length == 3) {
          hex = hex.split('').map((c) => '$c$c').join();
        }
        if (hex.length == 6) {
          hex = 'FF$hex';
        }
        return Color(int.parse(hex, radix: 16));
      } catch (_) {
        return null;
      }
    }
    return _parseColor(value.toLowerCase());
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
      case 'fuchsia':
        return Colors.pink;
      case 'lime':
        return Colors.lime;
      case 'maroon':
        return Colors.brown;
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
      default:
        return null;
    }
  }
}
