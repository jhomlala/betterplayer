///Class used to hold translations for all features within Better Player
class BetterPlayerTranslations {
  final String languageCode;
  final String generalDefaultError;
  final String generalNone;
  final String generalDefault;
  final String playlistLoadingNextVideo;
  final String controlsLive;
  final String controlsNextVideoIn;
  final String overflowMenuPlaybackSpeed;
  final String overflowMenuSubtitles;
  final String overflowMenuQuality;

  BetterPlayerTranslations({
    this.languageCode = "en",
    this.generalDefaultError = "Video can't be played",
    this.generalNone = "None",
    this.generalDefault = "Default",
    this.playlistLoadingNextVideo = "Loading next video",
    this.controlsLive = "LIVE",
    this.controlsNextVideoIn = "Next video in",
    this.overflowMenuPlaybackSpeed = "Playback speed",
    this.overflowMenuSubtitles = "Subtitles",
    this.overflowMenuQuality = "Quality",
  });

  factory BetterPlayerTranslations.polish() => BetterPlayerTranslations(
        languageCode: "pl",
        generalDefaultError: "Video nie może zostać odtworzone",
        generalNone: "Brak",
        generalDefault: "Domyślne",
        playlistLoadingNextVideo: "Ładowanie następnego filmu",
        controlsNextVideoIn: "Następne video za",
        overflowMenuPlaybackSpeed: "Szybkość odtwarzania",
        overflowMenuSubtitles: "Napisy",
        overflowMenuQuality: "Jakość",
      );

  factory BetterPlayerTranslations.chinese() => BetterPlayerTranslations(
        languageCode: "zh",
        generalDefaultError: "无法播放视频",
        generalNone: "没有",
        generalDefault: "默认",
        playlistLoadingNextVideo: "正在加载下一个视频",
        controlsLive: "直播",
        controlsNextVideoIn: "下一部影片n",
        overflowMenuPlaybackSpeed: "播放速度",
        overflowMenuSubtitles: "字幕",
        overflowMenuQuality: "质量",
      );

  factory BetterPlayerTranslations.hindi() => BetterPlayerTranslations(
        languageCode: "hi",
        generalDefaultError: "वीडियो नहीं चलाया जा सकता",
        generalNone: "कोई नहीं",
        generalDefault: "चूक",
        playlistLoadingNextVideo: "अगला वीडियो लोड हो रहा है",
        controlsLive: "लाइव",
        controlsNextVideoIn: "में अगला वीडियो",
        overflowMenuPlaybackSpeed: "प्लेबैक की गति",
        overflowMenuSubtitles: "उपशीर्षक",
        overflowMenuQuality: "गुणवत्ता",
      );
}
