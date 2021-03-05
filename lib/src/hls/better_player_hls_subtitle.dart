///Representation of HLS subtitle element.
class BetterPlayerHlsSubtitle {
  ///Language of the subtitle
  final String? language;

  ///Name of the subtitle
  final String? name;

  ///Url of the subtitle (master playlist)
  final String? url;

  ///Urls of specific files
  final List<String>? realUrls;

  BetterPlayerHlsSubtitle({
    this.language,
    this.name,
    this.url,
    this.realUrls,
  });
}
