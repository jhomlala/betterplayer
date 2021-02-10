import 'mime_types.dart';
import 'exception.dart';

class LibUtil {
  static bool startsWith(List<int> source, List<int> checker) {
    for (int i = 0; i < checker.length; i++)
      if (source[i] != checker[i]) return false;

    return true;
  }

  /// Returns `true` if [rune] represents a whitespace character.
  ///
  /// The definition of whitespace matches that used in [String.trim] which is
  /// based on Unicode 6.2. This maybe be a different set of characters than the
  /// environment's [RegExp] definition for whitespace, which is given by the
  /// ECMAScript standard: http://ecma-international.org/ecma-262/5.1/#sec-15.10
  static bool isWhitespace(int rune) =>
      (rune >= 0x0009 && rune <= 0x000D) ||
          rune == 0x0020 ||
          rune == 0x0085 ||
          rune == 0x00A0 ||
          rune == 0x1680 ||
          rune == 0x180E ||
          (rune >= 0x2000 && rune <= 0x200A) ||
          rune == 0x2028 ||
          rune == 0x2029 ||
          rune == 0x202F ||
          rune == 0x205F ||
          rune == 0x3000 ||
          rune == 0xFEFF;

  static String excludeWhiteSpace(String string) =>
      string.split('').where((it) => !isWhitespace(it.codeUnitAt(0))).join();

  static bool isLineBreak(int codeUnit) =>
      (codeUnit == '\n'.codeUnitAt(0)) || (codeUnit == '\r'.codeUnitAt(0));

  static String getCodecsOfType(String codecs, int trackType) {
    var output = Util.splitCodecs(codecs)
        .where((codec) => trackType == MimeTypes.getTrackTypeOfCodec(codec))
        .join(',');
    return output.isEmpty ? null : output;
  }

  static int parseXsDateTime(String value) {
    String pattern =
        '(\\d\\d\\d\\d)\\-(\\d\\d)\\-(\\d\\d)[Tt](\\d\\d):(\\d\\d):(\\d\\d)([\\.,](\\d+))?([Zz]|((\\+|\\-)(\\d?\\d):?(\\d\\d)))?';
    List<Match> matchList = RegExp(pattern).allMatches(value).toList();
    if (matchList.isEmpty)
      throw ParserException('Invalid date/time format: $value');
    Match match = matchList[0];
    int timezoneShift;
    if (match.group(9) == null) {
      // No time zone specified.
      timezoneShift = 0;
    } else if (match.group(9) == 'Z' || match.group(9) == 'z') {
      timezoneShift = 0;
    } else {
      timezoneShift =
          int.parse(match.group(12)) * 60 + int.parse(match.group(13));
      if ('-' == match.group(11)) timezoneShift *= -1;
    }

    //todo UTCではなくGMT?
    DateTime dateTime = DateTime.utc(
        int.parse(match.group(1)),
        int.parse(match.group(2)),
        int.parse(match.group(3)),
        int.parse(match.group(4)),
        int.parse(match.group(5)),
        int.parse(match.group(6)));
    if (match.group(8)?.isNotEmpty == true) {
      //todo ここ実装再検討
    }

    int time = dateTime.millisecondsSinceEpoch;
    if (timezoneShift != 0) {
      time -= timezoneShift * 60000;
    }

    return time;
  }

  static int msToUs(int timeMs) =>
      (timeMs == null || timeMs == Util.TIME_END_OF_SOURCE)
          ? timeMs
          : (timeMs * 1000);
}

class Util {
  static const int SELECTION_FLAG_DEFAULT = 1;
  static const int SELECTION_FLAG_FORCED = 1 << 1; // 2
  static const int SELECTION_FLAG_AUTOSELECT = 1 << 2; // 4
  static const int ROLE_FLAG_DESCRIBES_VIDEO = 1 << 9;
  static const int ROLE_FLAG_DESCRIBES_MUSIC_AND_SOUND = 1 << 10;
  static const int ROLE_FLAG_TRANSCRIBES_DIALOG = 1 << 12;
  static const int ROLE_FLAG_EASY_TO_READ = 1 << 13;

  /// A type constant for tracks of unknown type.
  static const int TRACK_TYPE_UNKNOWN = -1;

  /// A type constant for tracks of some default type, where the type itself is unknown.
  static const int TRACK_TYPE_DEFAULT = 0;

  /// A type constant for audio tracks.
  static const int TRACK_TYPE_AUDIO = 1;

  /// A type constant for video tracks.
  static const int TRACK_TYPE_VIDEO = 2;

  /// A type constant for text tracks.
  static const int TRACK_TYPE_TEXT = 3;

  /// A type constant for metadata tracks.
  static const int TRACK_TYPE_METADATA = 4;

  /// A type constant for camera motion tracks.
  static const int TRACK_TYPE_CAMERA_MOTION = 5;

  /// A type constant for a dummy or empty track.
  static const int TRACK_TYPE_NONE = 6;

  static const int TIME_END_OF_SOURCE = 0;

  static List<String> splitCodecs(String codecs) => codecs?.isNotEmpty != true
      ? <String>[]
      : codecs.trim().split(RegExp('(\\s*,\\s*)'));
}

class CencType {
  static const String CENC = 'TYPE_CENC';
  static const String CBCS = 'TYPE_CBCS';
}
