import 'package:better_player/src/core/better_player_utils.dart';

class BetterPlayerSubtitle {
  static const String timerSeparator = ' --> ';
  final int index;
  final Duration start;
  final Duration end;
  final List<String> texts;

  ///VTT OR SRT
  final String type;

  BetterPlayerSubtitle._({
    this.index,
    this.start,
    this.end,
    this.texts,
    this.type,
  });

  factory BetterPlayerSubtitle(String value) {
    try {
      final scanner = value.split('\n');
      if (scanner.length == 2) {
        return _handle2LinesSubtitles(scanner);
      }
      if (scanner.length > 2) {
        return _handle3LinesAndMoreSubtitles(scanner);
      }
      return BetterPlayerSubtitle._();
    } catch (exception) {
      BetterPlayerUtils.log("Failed to parse subtitle line: $value");
      return BetterPlayerSubtitle._();
    }
  }

  static BetterPlayerSubtitle _handle2LinesSubtitles(List<String> scanner) {
    try {
      final timeSplit = scanner[0].split(timerSeparator);
      final start = _stringToDuration(timeSplit[0]);
      final end = _stringToDuration(timeSplit[1]);
      final texts = scanner.sublist(1, scanner.length);

      return BetterPlayerSubtitle._(
          index: -1, start: start, end: end, texts: texts);
    } catch (exception) {
      BetterPlayerUtils.log("Failed to parse subtitle line: $scanner");
      return BetterPlayerSubtitle._();
    }
  }

  static BetterPlayerSubtitle _handle3LinesAndMoreSubtitles(
      List<String> scanner) {
    try {
      if (scanner[0].isEmpty) {
        scanner.removeAt(0);
      }

      final index = int.tryParse(scanner[0]);

      final timeSplit = scanner[1].split(timerSeparator);
      final start = _stringToDuration(timeSplit[0]);
      final end = _stringToDuration(timeSplit[1]);
      final texts = scanner.sublist(2, scanner.length);

      return BetterPlayerSubtitle._(
          index: index, start: start, end: end, texts: texts);
    } catch (exception) {
      BetterPlayerUtils.log("Failed to parse subtitle line: $scanner");
      return BetterPlayerSubtitle._();
    }
  }

  static Duration _stringToDuration(String value) {
    assert(value != null);
    try {
      final valueSplit = value.split(" ");
      String componentValue;

      if (valueSplit.length > 1) {
        componentValue = valueSplit[0];
      } else {
        componentValue = value;
      }

      final component = componentValue.split(':');
      if (component.length != 3) {
        return const Duration();
      }

      final secsAndMillisSplitChar = component[2].contains(',') ? ',' : '.';
      final secsAndMillsSplit = component[2].split(secsAndMillisSplitChar);
      if (secsAndMillsSplit.length != 2) {
        return const Duration();
      }

      final result = Duration(
          hours: int.tryParse(component[0]),
          minutes: int.tryParse(component[1]),
          seconds: int.tryParse(secsAndMillsSplit[0]),
          milliseconds: int.tryParse(secsAndMillsSplit[1]));
      return result;
    } catch (exception) {
      BetterPlayerUtils.log("Failed to process value: $value");
      return const Duration();
    }
  }
}
