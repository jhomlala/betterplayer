class BetterPlayerSubtitle {
  factory BetterPlayerSubtitle(String value) {
    final scanner = value.split('\n');
    if (scanner.length < 3) {
      return null;
    }
    if (scanner[0].isEmpty) {
      scanner.removeAt(0);
    }
    final index = int.parse(scanner[0]);
    final start = stringToDuration(scanner[1].split(timerSeparator)[0]);
    final end = stringToDuration(scanner[1].split(timerSeparator)[1]);
    final texts = scanner.sublist(2, scanner.length);

    return BetterPlayerSubtitle._(index: index, start: start, end: end, texts: texts);
  }

  BetterPlayerSubtitle._({this.index, this.start, this.end, this.texts});

  static const String timerSeparator = ' --> ';
  final int index;
  final Duration start;
  final Duration end;
  final List<String> texts;

  static Duration stringToDuration(String value) {
    final component = value.split(':');
    return Duration(
        hours: int.parse(component[0]),
        minutes: int.parse(component[1]),
        seconds: int.parse(component[2].split(',')[0]),
        milliseconds: int.parse(component[2].split(',')[1]));
  }
}