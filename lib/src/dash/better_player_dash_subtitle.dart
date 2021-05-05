///Representation of DASH subtitle element.
class BetterPlayerDashSubtitle {
  ///Language of the subtitle
  final String? language;

  ///MimeType of the subtitle
  final String? mimeType;

  ///SegmentAligment
  final bool? segmentAlignment;

  ///Url of the subtitle (master playlist)
  final String? url;

  BetterPlayerDashSubtitle({
    this.language,
    this.mimeType,
    this.segmentAlignment,
    this.url
  });
}
