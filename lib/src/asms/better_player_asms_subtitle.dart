///Representation of HLS / DASH subtitle element.
class BetterPlayerAsmsSubtitle {
  ///Language of the subtitle
  final String? language;

  ///Name of the subtitle
  final String? name;

  ///MimeType of the subtitle
  final String? mimeType;

  ///SegmentAligment
  final bool? segmentAlignment;

  ///Url of the subtitle (master playlist)
  final String? url;

  ///Urls of specific files
  final List<String>? realUrls;

  BetterPlayerAsmsSubtitle({
    this.language,
    this.name,
    this.mimeType,
    this.segmentAlignment,
    this.url,
    this.realUrls
  });
}
