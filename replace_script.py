import os
import glob
import re

replacements = {
    "_isFullScreen": "_viewState.isFullScreen",
    "_isPlayerVisible": "_viewState.isPlayerVisible",
    "_controlsAlwaysVisible": "_viewState.controlsAlwaysVisible",
    "_controlsEnabled": "_viewState.controlsEnabled",
    "_wasInPipMode": "_viewState.wasInPipMode",
    "_wasInFullScreenBeforePiP": "_viewState.wasInFullScreenBeforePiP",
    "_wasControlsEnabledBeforePiP": "_viewState.wasControlsEnabledBeforePiP",
    "_overriddenAspectRatio": "_viewState.overriddenAspectRatio",
    "_overriddenFit": "_viewState.overriddenFit",
    "_betterPlayerGlobalKey": "_viewState.betterPlayerGlobalKey",
    
    "_betterPlayerSubtitlesSourceList": "_subtitleState.subtitlesSourceList",
    "_betterPlayerSubtitlesSource": "_subtitleState.subtitlesSource",
    "subtitlesLines": "_subtitleState.subtitlesLines",
    "renderedSubtitle": "_subtitleState.renderedSubtitle",
    "_asmsSegmentsLoading": "_subtitleState.asmsSegmentsLoading",
    "_asmsSegmentsLoaded": "_subtitleState.asmsSegmentsLoaded",
    
    "_betterPlayerAsmsTracks": "_trackState.asmsTracks",
    "_betterPlayerAsmsTrack": "_trackState.asmsTrack",
    "_betterPlayerAsmsAudioTracks": "_trackState.asmsAudioTracks",
    "_betterPlayerAsmsAudioTrack": "_trackState.asmsAudioTrack",
    
    "_hasCurrentDataSourceStarted": "_playbackState.hasCurrentDataSourceStarted",
    "_hasCurrentDataSourceInitialized": "_playbackState.hasCurrentDataSourceInitialized",
    "_appLifecycleState": "_playbackState.appLifecycleState",
    "_wasPlayingBeforePause": "_playbackState.wasPlayingBeforePause",
    "_videoPlayerValueOnError": "_playbackState.videoPlayerValueOnError",
    "_lastPositionSelection": "_playbackState.lastPositionSelection",

    "BetterPlayerController._durationParameter": "PlayerEventConstants.durationParameter",
    "BetterPlayerController._progressParameter": "PlayerEventConstants.progressParameter",
    "BetterPlayerController._bufferedParameter": "PlayerEventConstants.bufferedParameter",
    "BetterPlayerController._volumeParameter": "PlayerEventConstants.volumeParameter",
    "BetterPlayerController._speedParameter": "PlayerEventConstants.speedParameter",
    "BetterPlayerController._dataSourceParameter": "PlayerEventConstants.dataSourceParameter",
    "BetterPlayerController._authorizationHeader": "PlayerEventConstants.authorizationHeader",

    "_durationParameter": "PlayerEventConstants.durationParameter",
    "_progressParameter": "PlayerEventConstants.progressParameter",
    "_bufferedParameter": "PlayerEventConstants.bufferedParameter",
    "_volumeParameter": "PlayerEventConstants.volumeParameter",
    "_speedParameter": "PlayerEventConstants.speedParameter",
    "_dataSourceParameter": "PlayerEventConstants.dataSourceParameter",
    "_authorizationHeader": "PlayerEventConstants.authorizationHeader",
}

files = glob.glob('packages/better_player/lib/src/core/**/*.dart', recursive=True)

for file in files:
    # Skip state files themselves and the constants file
    if 'state\\' in file or 'state/' in file or 'player_event_constants.dart' in file:
        continue
        
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content
    for old, new in replacements.items():
        if old.startswith('BetterPlayerController.'):
            content = content.replace(old, new)
        else:
            # Word boundary replacement
            content = re.sub(r'\b' + old + r'\b', new, content)
            
    if content != original:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {file}")

print("Done")
