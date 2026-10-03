import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xml/xml.dart';

/// Parser for TTML (Timed Text Markup Language / IMSC1 / DFXP) subtitles.
class PlayerTtmlParser {
  const PlayerTtmlParser();

  /// Parse TTML XML content into a list of [PlayerSubtitle] cues.
  List<PlayerSubtitle> parse({
    required String content,
    Duration timestampOffset = Duration.zero,
  }) {
    try {
      final document = XmlDocument.parse(content);
      final ttElement = document.findAllElements('tt').firstOrNull;
      if (ttElement == null) {
        PlayerLogger.warning(message: 'No <tt> root element found in TTML.');
        return const [];
      }

      final frameRate = _parseFrameRate(ttElement);
      final subFrameRate = _parseSubFrameRate(ttElement);
      final tickRate = _parseTickRate(
        ttElement: ttElement,
        effectiveFps: frameRate,
        subFrameRate: subFrameRate,
      );

      final styles = _parseStyles(document);
      final regions = _parseRegions(document: document, styles: styles);

      final cues = <PlayerSubtitle>[];
      var cueIndex = 1;

      final paragraphs = document.findAllElements('p');
      for (final p in paragraphs) {
        final beginStr = _getAttribute(element: p, localName: 'begin');
        final endStr = _getAttribute(element: p, localName: 'end');
        final durStr = _getAttribute(element: p, localName: 'dur');

        final beginDuration = _parseTime(
          timeStr: beginStr,
          effectiveFps: frameRate,
          subFrameRate: subFrameRate,
          tickRate: tickRate,
        );

        if (beginDuration == null && beginStr != null) {
          continue;
        }

        final ancestorOffset = _findAncestorTimeOffset(
          element: p,
          effectiveFps: frameRate,
          subFrameRate: subFrameRate,
          tickRate: tickRate,
        );

        final start =
            (beginDuration ?? Duration.zero) + ancestorOffset + timestampOffset;
        Duration? end;

        if (endStr != null) {
          final endDuration = _parseTime(
            timeStr: endStr,
            effectiveFps: frameRate,
            subFrameRate: subFrameRate,
            tickRate: tickRate,
          );
          if (endDuration != null) {
            end = endDuration + ancestorOffset + timestampOffset;
          }
        } else if (durStr != null) {
          final durDuration = _parseTime(
            timeStr: durStr,
            effectiveFps: frameRate,
            subFrameRate: subFrameRate,
            tickRate: tickRate,
          );
          if (durDuration != null) {
            end = start + durDuration;
          }
        }

        if (end == null || end <= start) {
          continue;
        }

        final alignment = _resolveAlignment(
          pElement: p,
          styles: styles,
          regions: regions,
        );

        final pStyle = _resolveElementStyle(element: p, styles: styles);
        final rawContent = _extractTextWithStyles(
          element: p,
          currentStyle: pStyle,
          styles: styles,
        );
        final rawLines = rawContent
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        final lines = rawLines
            .map((line) => _wrapWithStyles(text: line, style: pStyle))
            .where((line) => line.isNotEmpty)
            .toList();

        if (lines.isEmpty) {
          continue;
        }

        cues.add(
          PlayerSubtitle.fromData(
            index: cueIndex++,
            start: start,
            end: end,
            texts: lines,
            alignment: alignment,
          ),
        );
      }

      return cues;
    } catch (exception) {
      PlayerLogger.error(
        message: 'Failed to parse TTML content: $exception',
        error: exception,
      );
      return const [];
    }
  }

  static double _parseFrameRate(XmlElement ttElement) {
    final frameRateStr = _getAttribute(
      element: ttElement,
      localName: 'frameRate',
    );
    final baseFps = double.tryParse(frameRateStr ?? '') ?? 30.0;

    final multiplierStr = _getAttribute(
      element: ttElement,
      localName: 'frameRateMultiplier',
    );
    if (multiplierStr != null) {
      final parts = multiplierStr.trim().split(RegExp(r'\s+'));
      if (parts.length == 2) {
        final num = double.tryParse(parts[0]);
        final den = double.tryParse(parts[1]);
        if (num != null && den != null && den > 0) {
          return baseFps * (num / den);
        }
      }
    }
    return baseFps;
  }

  static int _parseSubFrameRate(XmlElement ttElement) {
    final subFrameRateStr = _getAttribute(
      element: ttElement,
      localName: 'subFrameRate',
    );
    return int.tryParse(subFrameRateStr ?? '') ?? 1;
  }

  static double _parseTickRate({
    required XmlElement ttElement,
    required double effectiveFps,
    required int subFrameRate,
  }) {
    final tickRateStr = _getAttribute(
      element: ttElement,
      localName: 'tickRate',
    );
    final tickRate = double.tryParse(tickRateStr ?? '');
    if (tickRate != null && tickRate > 0) {
      return tickRate;
    }
    return effectiveFps * subFrameRate;
  }

  static Duration? _parseTime({
    required String? timeStr,
    required double effectiveFps,
    required int subFrameRate,
    required double tickRate,
  }) {
    if (timeStr == null) {
      return null;
    }
    final trimmed = timeStr.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // 1. Timecount expressions: 10s, 500ms, 2m, 1h, 120f, 1000t
    final timecountMatch = RegExp(
      r'^([0-9]+(?:\.[0-9]+)?)(h|m|s|ms|f|t)$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (timecountMatch != null) {
      final val = double.tryParse(timecountMatch.group(1) ?? '') ?? 0.0;
      final metric = timecountMatch.group(2)?.toLowerCase();
      switch (metric) {
        case 'h':
          return Duration(microseconds: (val * 3600 * 1000000).round());
        case 'm':
          return Duration(microseconds: (val * 60 * 1000000).round());
        case 's':
          return Duration(microseconds: (val * 1000000).round());
        case 'ms':
          return Duration(microseconds: (val * 1000).round());
        case 'f':
          final sec = val / effectiveFps;
          return Duration(microseconds: (sec * 1000000).round());
        case 't':
          final sec = val / tickRate;
          return Duration(microseconds: (sec * 1000000).round());
      }
    }

    // 2. Clock-time expressions:
    // hh:mm:ss:ff or hh:mm:ss:ff.subframes
    // hh:mm:ss.fraction or hh:mm:ss
    final parts = trimmed.split(':');
    if (parts.length == 4) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;

      final framesPart = parts[3];
      var frames = 0.0;
      if (framesPart.contains('.')) {
        final frameSubparts = framesPart.split('.');
        final frameNum = double.tryParse(frameSubparts[0]) ?? 0.0;
        final subframeNum = double.tryParse(frameSubparts[1]) ?? 0.0;
        frames = frameNum + (subframeNum / subFrameRate);
      } else {
        frames = double.tryParse(framesPart) ?? 0.0;
      }

      final frameSec = frames / effectiveFps;
      final totalSec = hours * 3600 + minutes * 60 + seconds + frameSec;
      return Duration(microseconds: (totalSec * 1000000).round());
    }

    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final secAndFraction = parts[2].replaceAll(',', '.');
      final secDouble = double.tryParse(secAndFraction) ?? 0.0;

      final totalSec = hours * 3600 + minutes * 60 + secDouble;
      return Duration(microseconds: (totalSec * 1000000).round());
    }

    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final secAndFraction = parts[1].replaceAll(',', '.');
      final secDouble = double.tryParse(secAndFraction) ?? 0.0;

      final totalSec = minutes * 60 + secDouble;
      return Duration(microseconds: (totalSec * 1000000).round());
    }

    return null;
  }

  static Map<String, _TtmlStyle> _parseStyles(XmlDocument document) {
    final styles = <String, _TtmlStyle>{};
    final styleElements = document.findAllElements('style');
    for (final element in styleElements) {
      final id = _getId(element);
      if (id != null) {
        styles[id] = _TtmlStyle.fromElement(element);
      }
    }

    // Resolve style references
    final resolvedStyles = <String, _TtmlStyle>{};
    for (final entry in styles.entries) {
      resolvedStyles[entry.key] = _resolveStyleInheritance(
        styleId: entry.key,
        rawStyles: styles,
      );
    }
    return resolvedStyles;
  }

  static _TtmlStyle _resolveStyleInheritance({
    required String styleId,
    required Map<String, _TtmlStyle> rawStyles,
    Set<String>? visited,
  }) {
    final currentStyle = rawStyles[styleId];
    if (currentStyle == null) {
      return const _TtmlStyle();
    }

    final parentId = currentStyle.styleRef;
    if (parentId == null || (visited != null && visited.contains(parentId))) {
      return currentStyle;
    }

    final cycleGuard = visited ?? <String>{};
    cycleGuard.add(styleId);

    final parentStyle = _resolveStyleInheritance(
      styleId: parentId,
      rawStyles: rawStyles,
      visited: cycleGuard,
    );

    return parentStyle.merge(currentStyle);
  }

  static Map<String, _TtmlRegion> _parseRegions({
    required XmlDocument document,
    required Map<String, _TtmlStyle> styles,
  }) {
    final regions = <String, _TtmlRegion>{};
    final regionElements = document.findAllElements('region');
    for (final element in regionElements) {
      final id = _getId(element);
      if (id != null) {
        final region = _TtmlRegion.fromElement(
          element: element,
          styles: styles,
        );
        regions[id] = region;
      }
    }
    return regions;
  }

  static Alignment? _resolveAlignment({
    required XmlElement pElement,
    required Map<String, _TtmlStyle> styles,
    required Map<String, _TtmlRegion> regions,
  }) {
    final regionId = _findInheritedAttribute(
      element: pElement,
      localName: 'region',
    );
    final region = regionId != null ? regions[regionId] : null;

    final pStyle = _resolveElementStyle(element: pElement, styles: styles);

    final displayAlign = pStyle.displayAlign ?? region?.displayAlign ?? 'after';
    final textAlign = pStyle.textAlign ?? region?.textAlign ?? 'center';

    return _toAlignment(
      displayAlign: displayAlign.toLowerCase(),
      textAlign: textAlign.toLowerCase(),
    );
  }

  static Alignment? _toAlignment({
    required String displayAlign,
    required String textAlign,
  }) {
    final isTop = displayAlign == 'before';
    final isCenter = displayAlign == 'center';
    final isBottom = displayAlign == 'after';

    final isLeft = textAlign == 'left' || textAlign == 'start';
    final isRight = textAlign == 'right' || textAlign == 'end';

    if (isTop) {
      if (isLeft) return Alignment.topLeft;
      if (isRight) return Alignment.topRight;
      return Alignment.topCenter;
    }

    if (isCenter) {
      if (isLeft) return Alignment.centerLeft;
      if (isRight) return Alignment.centerRight;
      return Alignment.center;
    }

    if (isBottom) {
      if (isLeft) return Alignment.bottomLeft;
      if (isRight) return Alignment.bottomRight;
      return Alignment.bottomCenter;
    }

    return null;
  }

  static _TtmlStyle _resolveElementStyle({
    required XmlElement element,
    required Map<String, _TtmlStyle> styles,
  }) {
    var resolved = const _TtmlStyle();

    // Resolve ancestor (e.g. <tt>, <div>) styles first
    final ancestors = <XmlElement>[];
    var current = element.parentElement;
    while (current != null) {
      ancestors.insert(0, current);
      if (current.name.local.toLowerCase() == 'tt') {
        break;
      }
      current = current.parentElement;
    }

    for (final ancestor in ancestors) {
      final styleRef = _getAttribute(element: ancestor, localName: 'style');
      if (styleRef != null) {
        final refParts = styleRef.trim().split(RegExp(r'\s+'));
        for (final ref in refParts) {
          final style = styles[ref];
          if (style != null) {
            resolved = resolved.merge(style);
          }
        }
      }
      resolved = resolved.merge(_TtmlStyle.fromElement(ancestor));
    }

    final styleRef = _getAttribute(element: element, localName: 'style');
    if (styleRef != null) {
      final refParts = styleRef.trim().split(RegExp(r'\s+'));
      for (final ref in refParts) {
        final style = styles[ref];
        if (style != null) {
          resolved = resolved.merge(style);
        }
      }
    }
    final inlineStyle = _TtmlStyle.fromElement(element);
    return resolved.merge(inlineStyle);
  }

  static String? _findInheritedAttribute({
    required XmlElement element,
    required String localName,
  }) {
    XmlElement? current = element;
    while (current != null) {
      final val = _getAttribute(element: current, localName: localName);
      if (val != null) {
        return val;
      }
      if (current.name.local.toLowerCase() == 'tt') {
        break;
      }
      current = current.parentElement;
    }
    return null;
  }

  static Duration _findAncestorTimeOffset({
    required XmlElement element,
    required double effectiveFps,
    required int subFrameRate,
    required double tickRate,
  }) {
    var offset = Duration.zero;
    var current = element.parentElement;
    while (current != null) {
      final beginStr = _getAttribute(element: current, localName: 'begin');
      if (beginStr != null) {
        final dur = _parseTime(
          timeStr: beginStr,
          effectiveFps: effectiveFps,
          subFrameRate: subFrameRate,
          tickRate: tickRate,
        );
        if (dur != null) {
          offset += dur;
        }
      }
      if (current.name.local.toLowerCase() == 'tt') {
        break;
      }
      current = current.parentElement;
    }
    return offset;
  }

  static String _extractTextWithStyles({
    required XmlElement element,
    required _TtmlStyle currentStyle,
    required Map<String, _TtmlStyle> styles,
  }) {
    final buffer = StringBuffer();

    for (final node in element.children) {
      if (node is XmlText) {
        buffer.write(node.value);
      } else if (node is XmlElement) {
        final localName = node.name.local.toLowerCase();
        if (localName == 'br') {
          buffer.write('\n');
        } else if (localName == 'span') {
          final spanResolved = _resolveElementStyle(
            element: node,
            styles: styles,
          );
          final mergedSpanStyle = currentStyle.merge(spanResolved);
          final diffStyle = mergedSpanStyle.diffFrom(currentStyle);
          final innerContent = _extractTextWithStyles(
            element: node,
            currentStyle: mergedSpanStyle,
            styles: styles,
          );
          buffer.write(_wrapWithStyles(text: innerContent, style: diffStyle));
        } else {
          buffer.write(
            _extractTextWithStyles(
              element: node,
              currentStyle: currentStyle,
              styles: styles,
            ),
          );
        }
      }
    }

    return buffer.toString();
  }

  static String _wrapWithStyles({
    required String text,
    required _TtmlStyle style,
  }) {
    if (text.isEmpty) {
      return text;
    }
    if (text.contains('\n')) {
      return text
          .split('\n')
          .map((line) => _wrapWithStyles(text: line, style: style))
          .join('\n');
    }

    var result = text;
    if (style.isBold == true) {
      result = '<b>$result</b>';
    }
    if (style.isItalic == true) {
      result = '<i>$result</i>';
    }
    if (style.isUnderline == true) {
      result = '<u>$result</u>';
    }
    if (style.color != null && style.color!.isNotEmpty) {
      result = '<font color="${style.color}">$result</font>';
    }
    return result;
  }

  static String? _getId(XmlElement element) {
    return _getAttribute(element: element, localName: 'id');
  }

  static String? _getAttribute({
    required XmlElement element,
    required String localName,
  }) {
    final match = element.attributes.firstWhereOrNull(
      (attr) => attr.name.local.toLowerCase() == localName.toLowerCase(),
    );
    return match?.value;
  }
}

class _TtmlStyle {
  const _TtmlStyle({
    this.color,
    this.isBold,
    this.isItalic,
    this.isUnderline,
    this.textAlign,
    this.displayAlign,
    this.styleRef,
  });

  factory _TtmlStyle.fromElement(XmlElement element) {
    final color = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'color',
    );
    final fontWeight = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'fontWeight',
    );
    final fontStyle = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'fontStyle',
    );
    final textDecoration = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'textDecoration',
    );
    final textAlign = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'textAlign',
    );
    final displayAlign = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'displayAlign',
    );
    final styleRef = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'style',
    );

    return _TtmlStyle(
      color: color,
      isBold: fontWeight != null ? fontWeight.toLowerCase() == 'bold' : null,
      isItalic: fontStyle != null ? fontStyle.toLowerCase() == 'italic' : null,
      isUnderline: textDecoration?.toLowerCase().contains('underline'),
      textAlign: textAlign,
      displayAlign: displayAlign,
      styleRef: styleRef,
    );
  }

  final String? color;
  final bool? isBold;
  final bool? isItalic;
  final bool? isUnderline;
  final String? textAlign;
  final String? displayAlign;
  final String? styleRef;

  _TtmlStyle merge(_TtmlStyle other) {
    return _TtmlStyle(
      color: other.color ?? color,
      isBold: other.isBold ?? isBold,
      isItalic: other.isItalic ?? isItalic,
      isUnderline: other.isUnderline ?? isUnderline,
      textAlign: other.textAlign ?? textAlign,
      displayAlign: other.displayAlign ?? displayAlign,
      styleRef: other.styleRef ?? styleRef,
    );
  }

  _TtmlStyle diffFrom(_TtmlStyle parent) {
    return _TtmlStyle(
      color: (color != null && color != parent.color) ? color : null,
      isBold: (isBold == true && parent.isBold != true) ? true : null,
      isItalic: (isItalic == true && parent.isItalic != true) ? true : null,
      isUnderline: (isUnderline == true && parent.isUnderline != true)
          ? true
          : null,
      textAlign: textAlign,
      displayAlign: displayAlign,
      styleRef: styleRef,
    );
  }
}

class _TtmlRegion {
  const _TtmlRegion({this.displayAlign, this.textAlign});

  factory _TtmlRegion.fromElement({
    required XmlElement element,
    required Map<String, _TtmlStyle> styles,
  }) {
    var displayAlign = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'displayAlign',
    );
    var textAlign = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'textAlign',
    );

    final styleRef = PlayerTtmlParser._getAttribute(
      element: element,
      localName: 'style',
    );
    if (styleRef != null) {
      final style = styles[styleRef];
      if (style != null) {
        displayAlign ??= style.displayAlign;
        textAlign ??= style.textAlign;
      }
    }

    return _TtmlRegion(displayAlign: displayAlign, textAlign: textAlign);
  }

  final String? displayAlign;
  final String? textAlign;
}
