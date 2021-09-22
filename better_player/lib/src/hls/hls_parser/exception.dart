class ParserException implements Exception {
  ParserException(this.message) : super();

  final String message;

  @override
  String toString() => 'SignalException: $message';
}

class UnrecognizedInputFormatException extends ParserException {
  UnrecognizedInputFormatException(String message, this.uri) : super(message);

  final Uri? uri;
}
