## 0.0.83
* Updated dependencies
* Fixed Flutter 3.0 issues

## 0.0.82
* Updated ExoPlayer version to 2.17.1.
* Updated dependencies.
* Android native code refactor.

## 0.0.81
* Fixed full screen button padding in material controls.
* Added `setBetterPlayerControlsConfiguration` in `BetterPlayerController`.
* Added `setOverriddenFit` in `BetterPlayerController`.

## 0.0.80
* Removed pedantic dependency.
* Updated dependencies.
* Fixed controls render issue for small player (by https://github.com/admarwick)
* Fixed deprecated jCenter. Replaced jCenter with mavenCentral (by https://github.com/petoknm)
* Fixed iOS GCDWebServer and PINCache import issue (by https://github.com/twogood)
* Added is mounted check in player controls (by https://github.com/masoudk2000)
* Updated installation documentation page.

## 0.0.79
* Fixed kotlin version issue.

## 0.0.78
* [BREAKING_CHANGE] Split controlsHidden into controlsHiddenStart and controlsHiddenEnd.
* [BREAKING_CHANGE] Added to Function(bool) onPlayerVisibilityChanged to customControlsBuilder in [BetterPlayerConfiguration].
* Migrated android native code to Kotlin.
* Updated ExoPlayer version to 2.15.1.
* Updated screenshots.
* Added onTapDown handle for material and cupertino progress bar to handle show and hide of controls.
* Fixed crash related to Android 12.
* Fixed issue with full url of subtitle for HLS data source.
* Fixed install page from docs.
* Fixed one of the showcase images.
* Fixed video in list example.

## 0.0.77
* Fixed full screen safe area issue in cupertino controls.
* Fixed subtitles duplication after changing data source.
* Fixed progress bar issues when changing position of the video.
* [BREAKING_CHANGE] Changed min. Flutter version to 2.2.3.
* Changed log level in ExoPlayer to Error.
* Added url parameter for changedResolution event.
* Added [videoExtension] support for network data source for scenario where video source has no extension and cache manager requires it.
* Added parameters to [changedTrack] event.
* Added [changedPlaylistItem] event.
* Added [autoDetectFullscreenAspectRatio] parameter in [BetterPlayerConfiguration] (by https://github.com/Brazol)
* Updated license.
* Updated screenshots.

## 0.0.76
* Fixed iOS build issue.
* [BREAKING_CHANGE] Changed min required iOS version to 11.
* Updated `BetterPlayerConfiguration` `copyWith` method.
* Added `useRootNavigator` option to `BetterPlayerConfiguration`.

## 0.0.75
* Fixed iOS build issue.

## 0.0.74
* [BREAKING_CHANGE] `nextVideoTimeStreamController` is now marked as private. Please use `nextVideoTimeStream` to access stream.
* [BREAKING_CHANGE] Removed BackdropFilter from cupertino theme.
* [BREAKING_CHANGE] Removed `sigmaX` and `sigmaY` parameters from BetterPlayerControlsConfiguration.
* Added `expandToFill` in `BetterPlayerConfiguration`.
* Added `BetterPlayerControlsConfiguration.theme` factory for `BetterPlayerControlsConfiguration`.
* Added null checks in seek commands in `BetterPlayerControlsState`.
* Added tests.
* Added iOS HLS caching based on HLSCachingReverseProxyServer.
* Added default subtitle support for ASMS HLS data source (by https://github.com/siloebb).
* Fixed issue with live stream where player controls were always visible.
* Fixed iOS seek issue.
* Fixed getting started button link in documentation.
* Changed iOS non-HLS caching implementation based on https://github.com/neekeetab/CachingPlayerItem (by https://github.com/themadmrj).
* Fixed hardcoded 30 FPS on iOS (by https://github.com/antonkrasov).
* Enabled `preCache` and `stopPreCache` for iOS.
* Updated dependencies.

## 0.0.73
* Added `licenseUrl` support for iOS DRM.
* Fixed RTL text direction issue in player controls.
* Added `renderedSubtitle` in `BetterPlayerController`.
* Added additional check in `postControllerEvent` to handle scenario where event stream is closed.
* Updated ExoPlayer version
* Fixed `bufferingUpdate` event triggered too often.
* Updated video list example with bufering configuration.
* Updated video list documentation.
* Added `setMixWithOthers` method in `BetterPlayerListVideoPlayerController`.
* Fixed broken link in cover page of documentation.
* Fixed progress bar issue where position could be set above video duration.
* Fixed iOS remote notification command issue.
* Removed duplicated page in example app (by https://github.com/pinguluk)
* Added support for clear key DRM (by https://github.com/tinusneethling)
* Refreshed look and feel of the player UI (by https://github.com/creativeblaq)
* Added `sigmaX` and `sigmaY` parameters in BetterPlayerControlsConfiguration to control blur of cupertino controls (original idea by: https://github.com/YeFei572)

## 0.0.72
* Updated ExoPlayer version

## 0.0.71
* Fixed play after seeking issue on iOS.
* Fixed audio track selection issue on iOS/Android.
* Fixed issue where speed which couldn't be applied on iOS was saved in player state.
* Added support for D-pad navigation using a Android TV remote control (by https://github.com/danielz-nenda)
* Added `BetterPlayerMultipleGestureDetector` to handle problems with gesture detection
* Expose getter for `eventListeners` in `BetterPlayerController` (by https://github.com/Letalus)
* Updated documentation
* Updated dependencies

## 0.0.70
* Fixed file data source exception. Right now user will be only warned.
* Fixed playback speed after seek in iOS.
* Fixed `overriddenDuration` behavior in iOS when passed `overriddenDuration` is longer than video duration.
* Fixed issue where controls were not updated after video finish.
* Fixed auto full screen orientation not enabled in iOS.
* Exposed ASMS classes.
* Exposed BetterPlayerControlsState to provide ways to build custom controls with additional menus.
* Added error handling for CacheWorker to prevent unexpected crashes.
* Added support for FairPlay EZDRM (by https://github.com/adrianByv and https://github.com/koldo92)
* Added `certificateUrl` parameter in BetterPlayerDrmConfiguration.
* Added support for custom buffering configuration in Android (by https://github.com/Letalus)
* Added `bufferingConfiguration` parameter in BetterPlayerConfiguration which contains buffering settings.


## 0.0.69
* Fixed cache clear on Android.
* Added file check for file data source.
* Fixed issue with black screen for some videos on iOS (by https://github.com/themadmrj)
* Fixed iOS eventSink issues. (by https://github.com/alextekartik)
* Added key parameter in BetterPlayerCacheConfiguration to provide way to re-use same video between app sessions.

## 0.0.68
* Added support for segmented subtitles.
* Added new fields in in BetterPlayerSubtitlesSource: `asmsIsSegmented`, `asmsSegmentsTime` and ` asmsSegments`. These fields shouldn't be configured
manually.
* Fixed parsing VTT subtitle timestamps with no hour component (by https://github.com/trms-alex).
* Fixed parsing VTT subtitles when there's no subtitles in the file (by https://github.com/trms-alex).
* Added ES translations (by https://github.com/koldo92).
* Fixed iOS Picture in Picture play/pause state.
* Updated dependencies.
* Updated iOS example configuration.

## 0.0.67
* Added support for DASH adaptive stream subtitles, audio tracks, tracks (by https://github.com/adrianByv)
* [BREAKING_CHANGE] Changed useHlsSubtitles, useHlsTracks, useHlsAudio to useAsmsSubtitles, useAsmsTracks, useAsmsAudio.
* Added DASH example.
* Fixed progress bar jumps when seeking video.
* Fixed end of video looping final second, and video stutter during AudioSession deactivation (by https://github.com/NicholasNagy)

## 0.0.66
* Added check in seek method to handle scenario when video wasn't ready to play.
* Added setupDataSourceList in BetterPlayerPlaylistController.
* Fixed playback stalled issue in iOS.
* Added pause on iOS dispose call.
* Added bufferedStart, bufferedUpdate, bufferedEnd events.
* Fixed full screen dismissed when new data source loaded.
* Added forget option for VisibilityDetectorController (by https://github.com/ChopinDavid).
* Added vietnamese translations (by https://github.com/thanhvn-57).

## 0.0.65
* Refactored Android notification image selection.
* Added headers parameter in BetterPlayerSubtitlesSource. Headers is an optional parameter.
* Added activityName to BetterPlayerNotificationConfiguration.
* Android notification will open back application (by https://github.com/shashikantdurge).
* Fixed playing audio-only resources in iOS.
* Updated Exo Player version.
* Fixed notification not updating correctly for playlists in Android.
* [BREAKING_CHANGE] Removed deprecated Android code. Better Player supports now only v2 embedding.

## 0.0.64
* Added Turkish translations (by https://github.com/smurat).
* Video fit fixes (by https://github.com/themadmrj).
* Fixed speed iOS issue.
* Fixed Android's notification image OOM issue.
* Fixed 0 second delay issue in playlist.
* Fixed drmHeaders to be sent in headers rather than request body (by https://github.com/FlutterSu)
* Added preCache, stopPreCache method in BetterPlayerController (coauthored with: https://github.com/themadmrj)
* [BREAKING_CHANGE] clearCache method doesn't require to setup data source in order to use.

## 0.0.63
* Fixed pause method in dispose.
* Added clearCache method in BetterPlayerController.
* Fixed reusable video player example issues.

## 0.0.62
* Refactored internal event handling.
* [BREAKING_CHANGE] Migrated to null safety.
* [BREAKING_CHANGE] Updated dart min version to 2.12.0.
* Fixed issue where player controls were immediately hidden.
* Removed cancelFullScreenDismiss parameter.
* Added initialization check for VideoPlayerController.
* Changed default value of enableProgressText to true in BetterPlayerControlsConfiguration.
* Setup first selected HLS Audio as default one.
* General bug fixes.

## 0.0.61
* Fixed fullscreenByDefault issue.
* Updated documentation.

## 0.0.60
* Updated documentation.
* Added null checking for videoPlayerController inside BetterPlayerController.
* Added setMixWithOthers method to BetterPlayerController.
* Added initialStartIndex in BetterPlayerPlaylistConfiguration.
* Fixed issue where player did not disposed properly on app quit.
* Added placeholder parameter in BetterPlayerDataSource.
* Fixed custom material full screen icons (by https://github.com/FelipeFernandesLeandro)

## 0.0.59
* Fixed WEBVTT subtitles parsing.
* Updated ExoPlayer version.
* Refactored ExoPlayer code.
* Added missing controller dispose from BetterPlayer widget dispose.
* Added fix for iOS aspect ratio issue.
* Fixed auto play issue where player starts video after load initialization process and player is not visible.
* Updated texts in examples.
* Added missing widevine DRM parameters (by https://github.com/FlutterSu).

## 0.0.58
* Added overflowModalColor and overflowModalTextColor in BetterPlayerControlsConfiguration.
* Disabled picture in picture in fullscreen mode.
* Fixed enabled parameter for skip back and forward.
* Fixed notification configuration null issue (by https://github.com/bounty1342)
* Added token based and widevine DRM support.
* Updated documentation.

## 0.0.57
* Fixed iOS HLS initialization issue.
* Fixed issue where video plays after resume even if it's not visible.
* Updated User-Agent picking for Android.
* Added auto option for quality selection.

## 0.0.56
* Fixed empty data source notification issue.
* Fixed WebVTT subtitles parsing issue.
* Fixed memory data source issue on iOS.
* Added videoExtension parameter for memory data source (works only with memory data source).
* Added videoFormat parameter to network data source.
* Fixed controls visible all time on live stream.
* Fixed potential iOS notification crash.

## 0.0.55
* Dart analysis fix

## 0.0.54
* Refactored BetterPlayerPlaylist feature.
* Added new BetterPlayerPlaylistController which is accessible from BetterPlayerPlaylist's current
state. Playlist video can be changed with setupDataSource method and current video index can be
accessed with currentDataSourceIndex getter.
* Fixed iOS availableDuration index issue.
* Added arabic translations (by https://github.com/mohamed-Etman).
* Added headers to HLS data request (by https://github.com/mohamed-Etman).
* Added fullScreenAspectRatio to copyWith method in BetterPlayerConfiguration (by https://github.com/njlawton)

## 0.0.53
* Fixed fullscreen issue.
* Fixed HLS tracks selection.
* Removed HLS parser package and included HLS parser package in Better Player.
* Removed unused player observer in iOS.
* Fixed cache issue in Android where multiple Better Player instances uses same directory.
* Fixed HLS parsing issue.
* Added HLS Audio example.

## 0.0.52
* Fixed unregister listener issue in iOS.
* Updated documentation.
* [BREAKING_CHANGE] BetterPlayerState visibility changed to private.
* Fixed HLS audio tracks playlist selection issue.
* Added enableProgressBarDrag in BetterPlayerControlsConfiguration.
* Fixed audio track picking in ExoPlayer (Android).
* Changed default loadingColor.

## 0.0.51
* Fixed lint issues.
* Fixed subtitles setup issue.

## 0.0.50
* Fixed deprecated resizeToAvoidBottomPadding
* Fixed playing large videos in iOS.
* [BREAKING_CHANGE] Removed autoPlay and errorBuilder from BetterPlayerController. These can be accessed via betterPlayerController.
* Added HLS Audio track support.
* Added setAudioTrack method in BetterPlayerController.
* Added useHlsAudioTrack parameter in BetterPlayerDataSource.
* Added enableAudioTracks and audioTracksIcon, backgroundColor in BetterPlayerControlsConfiguration.
* Fixed HLS loading speed.
* Fixed finished event creation.
* Fixed player pause issue when player notification is displayed.
* Fixed player not pausing/resuming automatically correctly.

## 0.0.49
* Fixed fullscreen dispose issue.
* Added videoFormat parameter in BetterPlayerDataSource (should be used when data source url has no extension).
* Added retry feature after video failed to load.
* Added enableRetry in BetterPlayerControlsConfiguration.
* Changed BetterPlayerEventType.openFullscreen and BetterPlayerEventType.hideFullscreen events behavior (now events trigger after route change).
* Removed closed caption support from original video_player codebase.
* Fixed chinese translation typo (fixed by https://github.com/Big7lion)

## 0.0.48
* Fixed loading large videos in iOS.
* Fixed partly progress bar jumping when seek issue in iOS.
* Added forceDispose parameter to dispose method in BetterPlayerController.
* Fixed Android notification vibration issue (fixed by https://github.com/marcusforsberg).

## 0.0.47
* Fixed Android loading indicator issue.
* Added setControlsAlwaysVisible in BetterPlayerController.
* Added absolutePosition feature (added by https://github.com/FlutterSu)

## 0.0.46
* Fixed iOS AVPlayer observer issue.
* Fixed iOS headers not applied issue.

## 0.0.45
* Added Picture in Picture support.
* Added new parameters in BetterPlayerControlsConfiguration: pipMenuIcon and enablePip.
* Added new methods in BetterPlayerController: enablePictureInPicture, disablePictureInPicture, isPictureInPictureSupported,
setBetterPlayerGlobalKey.
* Added Picture in Picture icon in player controls.
* Added Picture in Picture example.
* Updated ExoPlayer version.
* Added pipStart and pipStop events.
* [BREAKING_CHANGE] Removed skipsTimeInMilliseconds. Added forwardSkipTimeInMilliseconds and backwardSkipTimeInMilliseconds.
* Updated notification service in android example.
* Fixed event play/pause event not triggered when controlling video with PiP or remote notification.
* Fixed playerTheme not set correctly.
* Fixed progress bar able to drag over other buttons.
* Fixed iOS player last second issue (player did not complete on last second of resource).

## 0.0.44
* Added placeholder until play example
* Added playback stalled feature in iOS. iOS version should behave same as Android once video failed to load.
* Added BetterPlayerTheme to controls configuration (added by https://github.com/maine98).
* [BREAKING_CHANGE] Changed custom controls builder in BetterPlayerControlsConfiguration. Now it accepts BetterPlayerController.
* Exposed BetterPlayerPlaylistState and betterPlayerController getter within.
* Added overriddenDuration to BetterPlayerDataSource.

## 0.0.43
* Added autoDispose flag in BetterPlayerConfiguration
* Added removeEventsListener in BetterPlayerController
* Video list examples update
* Fixed Android native build warnings
* Fixed placeholder until play issues
* Added placeholderOnTop to the BetterPlayerConfiguration
* Lint fixes

## 0.0.42
* Fixed resolution issue
* Fixed type of BetterPlayerDataSource for file type
* Added audio notify on dispose (iOS) (fixed by https://github.com/kingiol)

## 0.0.41
* Fixed loadingColor and loadingWidget for cupertino player
* Increased size of cupertino buttons
* Fixed setControlsEnabled in cupertino/material player
* [BREAKING_CHANGE] Removed startAt, looping, placeholder, overlay, fullScreenByDefault,
 allowedScreenSleep, systemOverlaysAfterFullScreen, deviceOrientationsAfterFullScreen from BetterPlayerController

## 0.0.40
* Exposed VideoPlayerValue in export
* Fixed log issue
* Added loadingColor and loadingWidget in BetterPlayerControlsConfiguration

## 0.0.39
* Added lint library for dart analysis
* [BREAKING_CHANGE] Changed constant names to lowerCamelCase in BetterPlayerDataSourceType
* [BREAKING_CHANGE] Changed constant names to lowerCamelCase in BetterPlayerEventType
* [BREAKING_CHANGE] Changed constant names to lowerCamelCase in BetterPlayerSubtitlesSourceType

## 0.0.38
* Added support for player notifications
* Added handleLifecycle to BetterPlayerConfiguration
* Added notificationConfiguration to BetterPlayerDataSource

## 0.0.37
* Added setControlsEnabled to BetterPlayerController
* Fixed example video list widget buttons not rendering correctly in small resolutions
* Added setOverriddenAspectRatio to BetterPlayerController
* Fixed crash connected with setSpeed in Android platform
* Fixed deviceOrientationsOnFullScreen for iOS
* Fixed CH translations (fixes by https://github.com/JarvanMo)
* Click to show/hide controls (fixed by https://github.com/mtAlves)
* [BREAKING_CHANGE] Removed future from isPlaying. Now it's sync method (https://github.com/hongfeiyang)

## 0.0.36
* Added INITIALIZED event
* Added autoDetectFullscreenDeviceOrientation in BetterPlayerConfiguration
* Fixed autoPlay background issue
* Removed open_iconic_flutter icons used in Cupertino controls
* Added cupertino_icons for icons used Cupertiono controls
* Fixed progress bar not working correctly for iOS 12 with file datasource
* Removed yellow line below progress text (fixed by https://github.com/mtAlves)

## 0.0.35
* Fixed iOS black screen issue
* Fixed full screen placeholder issue
* Fixed event not firing in enterFullScreen and exitFullScreen
* Fixed subtitles parsing issues

## 0.0.34
* Added memory data source
* Added factories: network, file, memory for BetterPlayerDataSource
* Fixed missing useHlsTracks implementation
* Fixed placeholder showing after full screen when using showPlaceholderUntilPlay
* Added setControlsVisibility to BetterPlayerController
* [BREAKING_CHANGE] Removed showControlsOnInitialize from BetterPlayerConfiguration. Use BetterPlayerControlsConfiguration to set showControlsOnInitialize parameter.
* Fixed cupertino controls issue with hasError

## 0.0.33
* Fixed BetterPlayerEvent visibility
* Fixed lazy initialization, when first data source is passed after player finishes first render
* Added selectedByDefault to BetterPlayerSubtitlesConfiguration
* Fixed HLS tracks android native code
* Updated example

## 0.0.32
* Fixed locale picking when context is not mounted anymore
* Added cache feature (based on https://github.com/sanekyy/plugins/tree/caching and https://github.com/vikram25897/flutter_cached_video_player solutions)
* Added BetterPlayerCacheConfiguration to BetterPlayerDataSource
* Refactored Android's native code

## 0.0.31
* Added showPlaceholderUntilPlay in BetterPlayerConfiguration
* Fixed exception event not being triggered
* Fixed controls not displaying on video finished

## 0.0.30
* Fixed issue when full screen was triggered twice if autoPlay and fullScreenByDefault were enabled
* Removed flutter_widgets, since it's not maintained anymore. Added instead visibility_detector package (by https://github.com/espresso3389)
* Added rewind and forward buttons for android player.
* Fixed player UI's jank
* Added enableSkips and skipsTimeInMilliseconds in BetterPlayerControlsConfiguration
* Changed middle play button behavior (now it's only used for restart player).
* Updated BetterPlayerControllerProvider visibility.
* Override invalid dependency from wakelock library.

## 0.0.29+1
* Updated readme

## 0.0.29
* Fixed routePageBuilder usage from BetterPlayerConfiguration
* Added overflowMenuIcon, playbackSpeedIcon, qualitiesIcon, subtitlesIcon, overflowMenuIconsColor to BetterPlayerControlsConfiguration
* Added double tap to play/pause video (original idea by https://github.com/r6c)

## 0.0.28
* Fixed subtitles overflow issue when transitioning between fullscreen and normal state
* Added alignment and backgroundColor in BetterPlayerSubtitlesConfiguration

## 0.0.27
* Added enableOverflowMenu option in BetterPlayerControlsConfiguration (enable/disable overflow menu)
* Added overflowMenuCustomItems in BetterPlayerControlsConfiguration (show custom menu items in overflow menu)
* [BREAKING_CHANGE] Removed defaultErrorText, loadingNextVideoText, liveText from BetterPlayerControlsConfiguration. To change these values, please use translations in BetterPlayerConfiguration.
* Added BetterPlayerTranslations in BetterPlayerConfiguration. You can use it to setup translations of the player.

## 0.0.26
* Added fullScreenAspectRatio and deviceOrientationsOnFullScreen to handle different full screen scenarios
* Updated wakelock version

## 0.0.25
* [BREAKING_CHANGE]: changed API in BetterPlayerControlsConfiguration: enableQualities replaces enableTracks.
* Added support for different video resolutions
* Fixed issue when full screen is being dismissed on changing subtitles
* Added CHANGED_RESOLUTION event

## 0.0.24
* Added possibility to set multiple subtitles to video
* [BREAKING_CHANGE]: changed API in BetterPlayerDataSource. Instead of one subtitles object, list of subtitles is required.

## 0.0.23
* General bug fixes.
* Added playerVisibilityChangedBehavior in BetterPlayerConfiguration.
* Changed player behavior when player is not visible in viewport: if player was playing before leaving viewport it will be paused and if user views player again it will start playing automatically.
* Added BetterPlayer.network and BetterPlayer.file methods.
* Changed iOS & Android native classes name to prevent conflict issues with video_player.

## 0.0.22
* Added support for hls tracks (quality of the videos).
* Added useHlsTracks and hlsTrackName in BetterPlayerDataSource.
* Added CHANGED_TRACK event.
* You can choose track from overflow menu. When there's no tracks to select "Default" will be selected.

## 0.0.21
* Added enableSubtitles parameter.

## 0.0.20
* Added rotation parameter in BetterPlayerConfiguration.

## 0.0.19
* Added support for hls subtitles (BetterPlayer will handle them automatically).
* [BREAKING_CHANGE]: changed API in BetterPlayerSubtitlesSource. To use old API, please use factory: BetterPlayerSubtitlesSource.single.
* Added useHlsSubtitles parameter in BetterPlayerDataSource.
* Added CHANGED_SUBTITLES event.
* User can choose subtitles from overflow menu, when there's no subtitles selected, "none" options will be chosen.

## 0.0.18:
* Fixed loading issue when auto play video feature is enabled in playlist.

## 0.0.17
* Fixed placeholder not following video fit options (fixed by https://github.com/nicholascioli).
* Updated dependencies.

## 0.0.16
* Added overflow menu.
* Added playback speed feature (based on https://github.com/shiyiya solution).
* User can choose playback speed from overflow menu.
* Added SET_SPEED event.

## 0.0.15
* Added fit configuration option (based on https://github.com/shiyiya solution).

## 0.0.14
* Better player list video player state is preserved on state changed.
* Fixed manual dispose issue.
* Fixed playlists video changing issue (fixed by https://github.com/sokolovstas).
* Added tap to hide feature for iOS player (by https://github.com/gazialankus).
* Fixed CONTROLS_VISIBLE and CONTROLS_HIDDEN events not triggered for ios player (fixed by https://github.com/gazialankus).
* Added seek method to BetterPlayerListVideoPlayerController.

## 0.0.13
* Changed channel name of video player plugin.
* Fixed dispose issue in cupertino player.

## 0.0.12
* Fixed duration called on null (fixed by https://github.com/ganeshrvel).
* Added new control events (fixed by https://github.com/ganeshrvel).
* Fixed .m3u8 live stream issues in iOS.

## 0.0.11
* Fixed iOS crash on dispose.
* Added player headers support.
* Updated dependencies.
* Dart Analysis refactor.

## 0.0.10
* Added BetterPlayerListVideoPlayerController to control list video player.

## 0.0.9
* Fixed setState called after dispose.
* General bugfixes.

## 0.0.8
* Fixed buffering indicator issue on Android.

## 0.0.7
* Fixed progress bar scroll lag.

## 0.0.6
* Fixed video duration issue.
* Added HTML subtitles.

## 0.0.5
* Added reusable video player.
* Bug fixes.

## 0.0.4
* Changed 'settings' to 'configuration'.
* Removed unused parameters from configuration.
* Documentation update.

## 0.0.3
* Updated documentation.

## 0.0.2
* Moved example project from better_player_example to example.

## 0.0.1
* Initial release.
