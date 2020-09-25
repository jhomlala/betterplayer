## 0.0.19
* Added support for hls subtitles (BetterPlayer will handle them automatically)
* [BREAKING_CHANGE]: changed API in BetterPlayerSubtitlesSource. To use old API, please use factory: BetterPlayerSubtitlesSource.single.
* Added useHlsSubtitles parameter for BetterPlayerDataSource
* Added CHANGED_SUBTITLES event
* User can choose subtitles from overflow menu, when there's no subtitles selected, "none" options will be chosen

## 0.0.18:
* Fixed loading issue when auto play video feature is enabled in playlist

## 0.0.17
* Fixed placeholder not following video fit options (fixed by https://github.com/nicholascioli)
* Updated dependencies

## 0.0.16
* Added overflow menu
* Added playback speed feature (based on https://github.com/shiyiya solution)
* User can choose playback speed from overflow menu
* Added SET_SPEED event

## 0.0.15
* Added fit configuration option (based on https://github.com/shiyiya solution).

## 0.0.14
* Better player list video player state is preserved on state changed
* Fixed manual dispose issue
* Fixed playlists video changing issue (fixed by https://github.com/sokolovstas)
* Added tap to hide feature for iOS player (by https://github.com/gazialankus)
* Fixed CONTROLS_VISIBLE and CONTROLS_HIDDEN events not triggered for ios player (fixed by https://github.com/gazialankus)
* Added seek method to BetterPlayerListVideoPlayerController

## 0.0.13
* Changed channel name of video player plugin
* Fixed dispose issue in cupertino player

## 0.0.12
* Fixed duration called on null (fixed by https://github.com/ganeshrvel)
* Added new control events (fixed by https://github.com/ganeshrvel)
* Fixed .m3u8 live stream issues in iOS

## 0.0.11
* Fixed iOS crash on dispose
* Added player headers support
* Updated dependencies
* Dart Analysis refactor

## 0.0.10
* Added BetterPlayerListVideoPlayerController to control list video player

## 0.0.9
* Fixed setState called after dispose
* General bugfixes

## 0.0.8
* Fixed buffering indicator issue on Android

## 0.0.7
* Fixed progress bar scroll lag

## 0.0.6
* Fixed video duration issue
* Added HTML subtitles

## 0.0.5
* Added reusable video player
* Bug fixes

## 0.0.4
* Changed 'settings' to 'configuration'
* Removed unused parameters from configuration
* Documentation update

## 0.0.3
* Updated documentation

## 0.0.2
* Moved example project from better_player_example to example

## 0.0.1

* Initial release
