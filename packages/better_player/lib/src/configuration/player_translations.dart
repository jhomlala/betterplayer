///Class used to hold translations for all features within Better Player
class PlayerTranslations {
  PlayerTranslations({
    this.languageCode = 'en',
    this.generalDefaultError = "Video can't be played",
    this.generalNone = 'None',
    this.generalDefault = 'Default',
    this.generalRetry = 'Retry',
    this.playlistLoadingNextVideo = 'Loading next video',
    this.controlsLive = 'LIVE',
    this.controlsNextVideoIn = 'Next video in',
    this.overflowMenuPlaybackSpeed = 'Playback speed',
    this.overflowMenuSubtitles = 'Subtitles',
    this.overflowMenuQuality = 'Quality',
    this.overflowMenuAudioTracks = 'Audio',
    this.qualityAuto = 'Auto',
    this.controlsPlayLabel = 'Play',
    this.controlsPauseLabel = 'Pause',
    this.controlsMuteLabel = 'Mute',
    this.controlsUnmuteLabel = 'Unmute',
    this.controlsFullscreenLabel = 'Enter fullscreen',
    this.controlsExitFullscreenLabel = 'Exit fullscreen',
    this.controlsSkipForwardLabel = 'Skip forward',
    this.controlsSkipBackwardLabel = 'Skip backward',
    this.progressBarLabel = 'Video progress',
    this.overflowMenuLabel = 'More options',
    this.controlsPipLabel = 'Picture-in-Picture',
  });

  factory PlayerTranslations.polish() => PlayerTranslations(
    languageCode: 'pl',
    generalDefaultError: 'Video nie może zostać odtworzone',
    generalNone: 'Brak',
    generalDefault: 'Domyślne',
    generalRetry: 'Spróbuj ponownie',
    playlistLoadingNextVideo: 'Ładowanie następnego filmu',
    controlsNextVideoIn: 'Następne video za',
    overflowMenuPlaybackSpeed: 'Szybkość odtwarzania',
    overflowMenuSubtitles: 'Napisy',
    overflowMenuQuality: 'Jakość',
    overflowMenuAudioTracks: 'Dźwięk',
    qualityAuto: 'Automatycznie',
    controlsPlayLabel: 'Odtwórz',
    controlsPauseLabel: 'Wstrzymaj',
    controlsMuteLabel: 'Wycisz',
    controlsUnmuteLabel: 'Wyłącz wyciszenie',
    controlsFullscreenLabel: 'Pełny ekran',
    controlsExitFullscreenLabel: 'Wyjdź z pełnego ekranu',
    controlsSkipForwardLabel: 'Do przodu',
    controlsSkipBackwardLabel: 'Do tyłu',
    progressBarLabel: 'Pasek postępu',
    overflowMenuLabel: 'Więcej opcji',
    controlsPipLabel: 'Obraz w obrazie',
  );

  factory PlayerTranslations.chinese() => PlayerTranslations(
    languageCode: 'zh',
    generalDefaultError: '无法播放视频',
    generalNone: '没有',
    generalDefault: '默认',
    generalRetry: '重試',
    playlistLoadingNextVideo: '正在加载下一个视频',
    controlsLive: '直播',
    controlsNextVideoIn: '下一部影片',
    overflowMenuPlaybackSpeed: '播放速度',
    overflowMenuSubtitles: '字幕',
    overflowMenuQuality: '质量',
    overflowMenuAudioTracks: '音訊',
    qualityAuto: '汽車',
    controlsPlayLabel: '播放',
    controlsPauseLabel: '暫停',
    controlsMuteLabel: '靜音',
    controlsUnmuteLabel: '取消靜音',
    controlsFullscreenLabel: '全屏',
    controlsExitFullscreenLabel: '退出全屏',
    controlsSkipForwardLabel: '快進',
    controlsSkipBackwardLabel: '快退',
    progressBarLabel: '視頻進度',
    overflowMenuLabel: '更多選項',
    controlsPipLabel: '畫中畫',
  );

  factory PlayerTranslations.hindi() => PlayerTranslations(
    languageCode: 'hi',
    generalDefaultError: 'वीडियो नहीं चलाया जा सकता',
    generalNone: 'कोई नहीं',
    generalDefault: 'चूक',
    generalRetry: 'पुनः प्रयास करें',
    playlistLoadingNextVideo: 'अगला वीडियो लोड हो रहा है',
    controlsLive: 'लाइव',
    controlsNextVideoIn: 'में अगला वीडियो',
    overflowMenuPlaybackSpeed: 'प्लेबैक की गति',
    overflowMenuSubtitles: 'उपशीर्षक',
    overflowMenuQuality: 'गुणवत्ता',
    overflowMenuAudioTracks: 'ऑडियो',
    qualityAuto: 'ऑटो',
    controlsPlayLabel: 'प्ले करें',
    controlsPauseLabel: 'पॉज करें',
    controlsMuteLabel: 'म्यूट करें',
    controlsUnmuteLabel: 'अनम्यूट करें',
    controlsFullscreenLabel: 'पूर्ण स्क्रीन करें',
    controlsExitFullscreenLabel: 'पूर्ण स्क्रीन से बाहर निकलें',
    controlsSkipForwardLabel: 'आगे बढ़ें',
    controlsSkipBackwardLabel: 'पीछे हटें',
    progressBarLabel: 'वीडियो प्रगति',
    overflowMenuLabel: 'अधिक विकल्प',
    controlsPipLabel: 'पिक्चर-इन-पिक्चर',
  );

  factory PlayerTranslations.arabic() => PlayerTranslations(
    languageCode: 'ar',
    generalDefaultError: 'لا يمكن تشغيل الفيديو',
    generalNone: 'لا يوجد',
    generalDefault: 'الاساسي',
    generalRetry: 'اعادة المحاوله',
    playlistLoadingNextVideo: 'تحميل الفيديو التالي',
    controlsLive: 'مباشر',
    controlsNextVideoIn: 'الفيديو التالي في',
    overflowMenuPlaybackSpeed: 'سرعة التشغيل',
    overflowMenuSubtitles: 'الترجمة',
    overflowMenuQuality: 'الجودة',
    overflowMenuAudioTracks: 'الصوت',
    qualityAuto: 'أوتوماتيكي',
    controlsPlayLabel: 'تشغيل',
    controlsPauseLabel: 'إيقاف مؤقت',
    controlsMuteLabel: 'كتم الصوت',
    controlsUnmuteLabel: 'إلغاء كتم الصوت',
    controlsFullscreenLabel: 'ملء الشاشة',
    controlsExitFullscreenLabel: 'خروج من ملء الشاشة',
    controlsSkipForwardLabel: 'تقديم',
    controlsSkipBackwardLabel: 'تأخير',
    progressBarLabel: 'تقدم الفيديو',
    overflowMenuLabel: 'المزيد من الخيارات',
    controlsPipLabel: 'صورة داخل صورة',
  );

  factory PlayerTranslations.turkish() => PlayerTranslations(
    languageCode: 'tr',
    generalDefaultError: 'Video oynatılamıyor',
    generalNone: 'Hiçbiri',
    generalDefault: 'Varsayılan',
    generalRetry: 'Tekrar Dene',
    playlistLoadingNextVideo: 'Sonraki video yükleniyor',
    controlsLive: 'CANLI',
    controlsNextVideoIn: 'Sonraki video oynatılmadan',
    overflowMenuPlaybackSpeed: 'Oynatma hızı',
    overflowMenuSubtitles: 'Altyazı',
    overflowMenuQuality: 'Kalite',
    overflowMenuAudioTracks: 'Ses',
    qualityAuto: 'Otomatik',
    controlsPlayLabel: 'Oynat',
    controlsPauseLabel: 'Duraklat',
    controlsMuteLabel: 'Sessiz',
    controlsUnmuteLabel: 'Sesi Aç',
    controlsFullscreenLabel: 'Tam Ekran',
    controlsExitFullscreenLabel: 'Tam Ekrandan Çık',
    controlsSkipForwardLabel: 'İleri Atla',
    controlsSkipBackwardLabel: 'Geri Atla',
    progressBarLabel: 'Video İlerlemesi',
    overflowMenuLabel: 'Daha Fazla Seçenek',
    controlsPipLabel: 'Resim içinde Resim',
  );

  factory PlayerTranslations.vietnamese() => PlayerTranslations(
    languageCode: 'vi',
    generalDefaultError: 'Video không thể phát bây giờ',
    generalNone: 'Không có',
    generalDefault: 'Mặc định',
    generalRetry: 'Thử lại ngay',
    controlsLive: 'Trực tiếp',
    playlistLoadingNextVideo: 'Đang tải video tiếp theo',
    controlsNextVideoIn: 'Video tiếp theo',
    overflowMenuPlaybackSpeed: 'Tốc độ phát',
    overflowMenuSubtitles: 'Phụ đề',
    overflowMenuQuality: 'Chất lượng',
    overflowMenuAudioTracks: 'Âm thanh',
    qualityAuto: 'Tự động',
    controlsPlayLabel: 'Phát',
    controlsPauseLabel: 'Tạm dừng',
    controlsMuteLabel: 'Tắt tiếng',
    controlsUnmuteLabel: 'Bật tiếng',
    controlsFullscreenLabel: 'Toàn màn hình',
    controlsExitFullscreenLabel: 'Thoát toàn màn hình',
    controlsSkipForwardLabel: 'Tua tới',
    controlsSkipBackwardLabel: 'Tua lùi',
    progressBarLabel: 'Tiến trình video',
    overflowMenuLabel: 'Thêm tùy chọn',
    controlsPipLabel: 'Hình trong hình',
  );

  factory PlayerTranslations.spanish() => PlayerTranslations(
    languageCode: 'es',
    generalDefaultError: 'No se puede reproducir el video',
    generalNone: 'Ninguno',
    generalDefault: 'Por defecto',
    generalRetry: 'Reintentar',
    controlsLive: 'EN DIRECTO',
    playlistLoadingNextVideo: 'Cargando siguiente video',
    controlsNextVideoIn: 'Siguiente video en',
    overflowMenuPlaybackSpeed: 'Velocidad',
    overflowMenuSubtitles: 'Subtítulos',
    overflowMenuQuality: 'Calidad',
    qualityAuto: 'Automática',
    controlsPlayLabel: 'Reproducir',
    controlsPauseLabel: 'Pausar',
    controlsMuteLabel: 'Silenciar',
    controlsUnmuteLabel: 'Activar sonido',
    controlsFullscreenLabel: 'Pantalla completa',
    controlsExitFullscreenLabel: 'Salir de pantalla completa',
    controlsSkipForwardLabel: 'Adelantar',
    controlsSkipBackwardLabel: 'Retroceder',
    progressBarLabel: 'Barra de progreso',
    overflowMenuLabel: 'Menú de opciones',
    controlsPipLabel: 'Imagen en imagen',
  );
  final String languageCode;
  final String generalDefaultError;
  final String generalNone;
  final String generalDefault;
  final String generalRetry;
  final String playlistLoadingNextVideo;
  final String controlsLive;
  final String controlsNextVideoIn;
  final String overflowMenuPlaybackSpeed;
  final String overflowMenuSubtitles;
  final String overflowMenuQuality;
  final String overflowMenuAudioTracks;
  final String qualityAuto;

  /// Accessibility labels
  final String controlsPlayLabel;
  final String controlsPauseLabel;
  final String controlsMuteLabel;
  final String controlsUnmuteLabel;
  final String controlsFullscreenLabel;
  final String controlsExitFullscreenLabel;
  final String controlsSkipForwardLabel;
  final String controlsSkipBackwardLabel;
  final String progressBarLabel;
  final String overflowMenuLabel;
  final String controlsPipLabel;
}
