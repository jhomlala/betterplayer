class BetterPlayerSubtitle {
  static const String timerSeparator = ' --> ';
  final int index;
  final Duration start;
  final Duration end;
  final List<String> texts;

  BetterPlayerSubtitle._({this.index, this.start, this.end, this.texts});

  factory BetterPlayerSubtitle(String value) {
    try {
      final scanner = value.split('\n');
      if (scanner.length < 3) {
        return null;
      }
      if (scanner[0].isEmpty) {
        scanner.removeAt(0);
      }
      final index = int.parse(scanner[0]);

      var timeSplit = scanner[1].split(timerSeparator);
      final start = _stringToDuration(timeSplit[0]);
      final end = _stringToDuration(timeSplit[1]);
      final texts = scanner.sublist(2, scanner.length);

      return BetterPlayerSubtitle._(
          index: index, start: start, end: end, texts: texts);
    } catch (exception) {
      print("Failed to parse subtitle line: $value");
      return BetterPlayerSubtitle._();
    }
  }

  static Duration _stringToDuration(String value) {
    assert(value != null);
    try {
      final component = value.split(':');
      if (component.length != 3) {
        return Duration();
      }

      var secsAndMillsSplit = component[2].split(',');
      if (secsAndMillsSplit.length != 2) {
        return Duration();
      }
      return Duration(
          hours: int.parse(component[0]),
          minutes: int.parse(component[1]),
          seconds: int.parse(secsAndMillsSplit[0]),
          milliseconds: int.parse(secsAndMillsSplit[1]));
    } catch (exception) {
      print("Failed to process value: $value");
      return Duration();
    }
  }
}
