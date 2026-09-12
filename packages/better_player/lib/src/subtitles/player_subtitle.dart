import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/webvtt_cue_alignment.dart';
import 'package:material_ui/material_ui.dart';

class PlayerSubtitle {
  factory PlayerSubtitle({
    required String value,
    required bool isWebVTT,
    Duration timestampOffset = Duration.zero,
  }) {
    try {
      final scanner = value.split('\n');
      if (scanner.length == 2) {
        return _handle2LinesSubtitles(
          scanner: scanner,
          timestampOffset: timestampOffset,
        );
      }
      if (scanner.length > 2) {
        return _handle3LinesAndMoreSubtitles(
          scanner: scanner,
          isWebVTT: isWebVTT,
          timestampOffset: timestampOffset,
        );
      }
      return PlayerSubtitle._();
    } catch (exception) {
      PlayerLogger.error(message: 'Failed to parse subtitle line: $value');
      return PlayerSubtitle._();
    }
  }

  PlayerSubtitle._({
    this.index,
    this.start,
    this.end,
    this.texts,
    this.alignment,
  });
  static const String timerSeparator = ' --> ';
  final int? index;
  final Duration? start;
  final Duration? end;
  final List<String>? texts;
  final Alignment? alignment;

  static PlayerSubtitle _handle2LinesSubtitles({
    required List<String> scanner,
    required Duration timestampOffset,
  }) {
    try {
      final timeAndSettings = scanner[0];
      final timeSplit = timeAndSettings.split(timerSeparator);
      final rawStart = stringToDuration(timeSplit[0]);
      final endTimePart = timeSplit[1];
      final endTimeSplit = endTimePart.split(' ');
      final rawEnd = stringToDuration(endTimeSplit[0]);

      Alignment? alignment;
      if (endTimeSplit.length > 1) {
        alignment = _parseCueSettings(endTimeSplit.sublist(1).join(' '));
      }

      final start = rawStart + timestampOffset;
      final end = rawEnd + timestampOffset;
      final texts = scanner.sublist(1, scanner.length);

      return PlayerSubtitle._(
        index: -1,
        start: start,
        end: end,
        texts: texts,
        alignment: alignment,
      );
    } catch (exception) {
      PlayerLogger.error(message: 'Failed to parse subtitle line: $scanner');
      return PlayerSubtitle._();
    }
  }

  static PlayerSubtitle _handle3LinesAndMoreSubtitles({
    required List<String> scanner,
    required bool isWebVTT,
    required Duration timestampOffset,
  }) {
    try {
      int? index = -1;
      var timeSplit = <String>[];
      var firstLineOfText = 0;
      Alignment? alignment;

      if (scanner[0].contains(timerSeparator)) {
        final timeAndSettings = scanner[0];
        timeSplit = timeAndSettings.split(timerSeparator);
        firstLineOfText = 1;
        final endTimePart = timeSplit[1];
        final endTimeSplit = endTimePart.split(' ');
        if (endTimeSplit.length > 1) {
          alignment = _parseCueSettings(endTimeSplit.sublist(1).join(' '));
          timeSplit[1] = endTimeSplit[0];
        }
      } else {
        index = int.tryParse(scanner[0]);
        final timeAndSettings = scanner[1];
        timeSplit = timeAndSettings.split(timerSeparator);
        firstLineOfText = 2;
        final endTimePart = timeSplit[1];
        final endTimeSplit = endTimePart.split(' ');
        if (endTimeSplit.length > 1) {
          alignment = _parseCueSettings(endTimeSplit.sublist(1).join(' '));
          timeSplit[1] = endTimeSplit[0];
        }
      }

      final rawStart = stringToDuration(timeSplit[0]);
      final rawEnd = stringToDuration(timeSplit[1]);
      final start = rawStart + timestampOffset;
      final end = rawEnd + timestampOffset;
      final texts = scanner.sublist(firstLineOfText, scanner.length);
      return PlayerSubtitle._(
        index: index,
        start: start,
        end: end,
        texts: texts,
        alignment: alignment,
      );
    } catch (exception) {
      PlayerLogger.error(message: 'Failed to parse subtitle line: $scanner');
      return PlayerSubtitle._();
    }
  }

  static Alignment? _parseCueSettings(String settings) {
    try {
      // Example: align:start line:0% position:20%
      final parts = settings.split(' ');
      for (final part in parts) {
        if (part.startsWith('align:')) {
          final alignVal = part.replaceFirst('align:', '').toLowerCase();
          final cueAlign = WebVttCueAlignment.values.firstWhere(
            (e) => e.name == alignVal,
            orElse: () => WebVttCueAlignment.center,
          );
          return cueAlign.toAlignment();
        }
      }
      return null;
    } catch (exception) {
      PlayerLogger.error(message: 'Failed to parse cue settings: $settings');
      return null;
    }
  }

  static Duration stringToDuration(String value) {
    try {
      final valueSplit = value.split(' ');
      String componentValue;

      if (valueSplit.length > 1) {
        componentValue = valueSplit[0];
      } else {
        componentValue = value;
      }

      final component = componentValue.split(':');
      // Interpret a missing hour component to mean 00 hours
      if (component.length == 2) {
        component.insert(0, '00');
      } else if (component.length != 3) {
        return const Duration();
      }

      final secsAndMillisSplitChar = component[2].contains(',') ? ',' : '.';
      final secsAndMillsSplit = component[2].split(secsAndMillisSplitChar);
      if (secsAndMillsSplit.length != 2) {
        return const Duration();
      }

      final result = Duration(
        hours: int.tryParse(component[0])!,
        minutes: int.tryParse(component[1])!,
        seconds: int.tryParse(secsAndMillsSplit[0])!,
        milliseconds: int.tryParse(secsAndMillsSplit[1])!,
      );
      return result;
    } catch (exception) {
      PlayerLogger.warning(message: 'Failed to process value: $value');
      return const Duration();
    }
  }

  @override
  String toString() {
    return 'PlayerSubtitle{index: $index, start: $start, end: $end, texts: $texts, alignment: $alignment}';
  }
}
