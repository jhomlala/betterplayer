// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BetterPlayerPlugin.h"
#import <better_player/better_player-Swift.h>

#if !__has_feature(objc_arc)
#error Code Requires ARC.
#endif


@implementation BetterPlayerPlugin
NSMutableDictionary* _dataSourceDict;
NSMutableDictionary*  _timeObserverIdDict;
NSMutableDictionary*  _artworkImageDict;
CacheManager* _cacheManager;
int texturesCount = -1;
BetterPlayer* _notificationPlayer;
bool _remoteCommandsInitialized = false;


#pragma mark - FlutterPlugin protocol
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel =
    [FlutterMethodChannel methodChannelWithName:@"better_player_channel"
                                binaryMessenger:[registrar messenger]];
    BetterPlayerPlugin* instance = [[BetterPlayerPlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
    //[registrar publish:instance];
    [registrar registerViewFactory:instance withId:@"com.jhomlala/better_player"];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _messenger = [registrar messenger];
    _registrar = registrar;
    _players = [NSMutableDictionary dictionaryWithCapacity:1];
    _timeObserverIdDict = [NSMutableDictionary dictionary];
    _artworkImageDict = [NSMutableDictionary dictionary];
    _dataSourceDict = [NSMutableDictionary dictionary];
    _cacheManager = [[CacheManager alloc] init];
    [_cacheManager setup];
    return self;
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    for (NSNumber* textureId in _players.allKeys) {
        BetterPlayer* player = _players[textureId];
        [player disposeSansEventChannel];
    }
    [_players removeAllObjects];
}

#pragma mark - FlutterPlatformViewFactory protocol
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    NSNumber* textureId = [args objectForKey:@"textureId"];
    BetterPlayerView* player = [_players objectForKey:@(textureId.intValue)];
    return player;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

#pragma mark - BetterPlayerPlugin class
- (int)newTextureId {
    texturesCount += 1;
    return texturesCount;
}
- (void)onPlayerSetup:(BetterPlayer*)player
               result:(FlutterResult)result {
    int64_t textureId = [self newTextureId];
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:[NSString stringWithFormat:@"better_player_channel/videoEvents%lld",
                                                               textureId]
                                         binaryMessenger:_messenger];
    [player setMixWithOthers:false];
    [eventChannel setStreamHandler:player];
    player.eventChannel = eventChannel;
    _players[@(textureId)] = player;
    result(@{@"textureId" : @(textureId)});
}

- (void) setupRemoteNotification :(BetterPlayer*) player{
    _notificationPlayer = player;
    [self stopOtherUpdateListener:player];
    NSDictionary* dataSource = [_dataSourceDict objectForKey:[self getTextureId:player]];
    BOOL showNotification = false;
    id showNotificationObject = [dataSource objectForKey:@"showNotification"];
    if (showNotificationObject != [NSNull null]) {
        showNotification = [[dataSource objectForKey:@"showNotification"] boolValue];
    }
    NSString* title = dataSource[@"title"];
    NSString* author = dataSource[@"author"];
    NSString* imageUrl = dataSource[@"imageUrl"];
    int64_t skipForwardTimeInMilliseconds = [dataSource[@"skipForwardTimeInMilliseconds"] intValue];
    int64_t skipBackwardTimeInMilliseconds = [dataSource[@"skipBackwardTimeInMilliseconds"] intValue];

    if (showNotification){
        [self setRemoteCommandsNotificationActive];
        [self setupRemoteCommands: player, skipForwardTimeInMilliseconds, skipBackwardTimeInMilliseconds];
        [self setupRemoteCommandNotification: player, title, author, imageUrl];
        [self setupUpdateListener: player, title, author, imageUrl];
    }
}

- (void) setRemoteCommandsNotificationActive{
    [[AVAudioSession sharedInstance] setActive:true error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void) setRemoteCommandsNotificationNotActive{
    if ([_players count] == 0) {
        [[AVAudioSession sharedInstance] setActive:false error:nil];
    }

    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}


- (void) setupRemoteCommands:(BetterPlayer*)player, skipForwardTimeInMilliseconds, skipBackwardTimeInMilliseconds {
    if (_remoteCommandsInitialized){
        return;
    }
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.togglePlayPauseCommand setEnabled:YES];
    [commandCenter.playCommand setEnabled:YES];
    [commandCenter.pauseCommand setEnabled:YES];
    [commandCenter.skipForwardCommand setEnabled:YES];
    [commandCenter.skipBackwardCommand setEnabled:YES];
    if (@available(iOS 9.1, *)) {
        [commandCenter.changePlaybackPositionCommand setEnabled:YES];
    }

    commandCenter.skipForwardCommand.preferredIntervals = @[@(skipForwardTimeInMilliseconds/1000)];
    commandCenter.skipBackwardCommand.preferredIntervals = @[@(skipBackwardTimeInMilliseconds/1000)];

    [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (_notificationPlayer != [NSNull null]){
            if (_notificationPlayer.isPlaying){
                _notificationPlayer.eventSink(@{@"event" : @"play"});
            } else {
                _notificationPlayer.eventSink(@{@"event" : @"pause"});
            }
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.playCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (_notificationPlayer != [NSNull null]){
            _notificationPlayer.eventSink(@{@"event" : @"play"});
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.pauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (_notificationPlayer != [NSNull null]){
            _notificationPlayer.eventSink(@{@"event" : @"pause"});
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.skipForwardCommand addTargetWithHandler:  ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (_notificationPlayer != [NSNull null]){
            int64_t millis = [_notificationPlayer position] + skipForwardTimeInMilliseconds;
            _notificationPlayer.eventSink(@{@"event" : @"seek", @"position": @(millis)});
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.skipBackwardCommand addTargetWithHandler:  ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (_notificationPlayer != [NSNull null]){
            int64_t millis = [_notificationPlayer position] - skipBackwardTimeInMilliseconds;
            _notificationPlayer.eventSink(@{@"event" : @"seek", @"position": @(millis)});
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    if (@available(iOS 9.1, *)) {
        [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            if (_notificationPlayer != [NSNull null]){
                MPChangePlaybackPositionCommandEvent * playbackEvent = (MPChangePlaybackRateCommandEvent * ) event;
                CMTime time = CMTimeMake(playbackEvent.positionTime, 1);
                int64_t millis = [BetterPlayerTimeUtils FLTCMTimeToMillis:(time)];
                [_notificationPlayer seekTo: millis];
                _notificationPlayer.eventSink(@{@"event" : @"seek", @"position": @(millis)});
            }
            return MPRemoteCommandHandlerStatusSuccess;
        }];
    }
    _remoteCommandsInitialized = true;
}

- (void) setupRemoteCommandNotification:(BetterPlayer*)player, NSString* title, NSString* author , NSString* imageUrl{
    float positionInSeconds = player.position /1000;
    float durationInSeconds = player.duration/ 1000;


    NSMutableDictionary * nowPlayingInfoDict = [@{MPMediaItemPropertyArtist: author,
                                                  MPMediaItemPropertyTitle: title,
                                                  MPNowPlayingInfoPropertyElapsedPlaybackTime: [ NSNumber numberWithFloat : positionInSeconds],
                                                  MPMediaItemPropertyPlaybackDuration: [NSNumber numberWithFloat:durationInSeconds],
                                                  MPNowPlayingInfoPropertyPlaybackRate: @1,
    } mutableCopy];

    if (imageUrl != [NSNull null]){
        NSString* key =  [self getTextureId:player];
        MPMediaItemArtwork* artworkImage = [_artworkImageDict objectForKey:key];

        if (key != [NSNull null]){
            if (artworkImage){
                [nowPlayingInfoDict setObject:artworkImage forKey:MPMediaItemPropertyArtwork];
                [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfoDict;

            } else {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(queue, ^{
                    @try{
                        UIImage * tempArtworkImage = nil;
                        if ([imageUrl rangeOfString:@"http"].location == NSNotFound){
                            tempArtworkImage = [UIImage imageWithContentsOfFile:imageUrl];
                        } else {
                            NSURL *nsImageUrl =[NSURL URLWithString:imageUrl];
                            tempArtworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:nsImageUrl]];
                        }
                        if(tempArtworkImage)
                        {
                            MPMediaItemArtwork* artworkImage = [[MPMediaItemArtwork alloc] initWithImage: tempArtworkImage];
                            [_artworkImageDict setObject:artworkImage forKey:key];
                            [nowPlayingInfoDict setObject:artworkImage forKey:MPMediaItemPropertyArtwork];
                        }
                        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfoDict;
                    }
                    @catch(NSException *exception) {

                    }
                });
            }
        }
    } else {
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfoDict;
    }
}



- (NSString*) getTextureId: (BetterPlayer*) player{
    NSArray* temp = [_players allKeysForObject: player];
    NSString* key = [temp lastObject];
    return key;
}

- (void) setupUpdateListener:(BetterPlayer*)player,NSString* title, NSString* author,NSString* imageUrl  {
    id _timeObserverId = [player.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time){
        [self setupRemoteCommandNotification:player, title, author, imageUrl];
    }];

    NSString* key =  [self getTextureId:player];
    [ _timeObserverIdDict setObject:_timeObserverId forKey: key];
}


- (void) disposeNotificationData: (BetterPlayer*)player{
    if (player == _notificationPlayer){
        _notificationPlayer = NULL;
        _remoteCommandsInitialized = false;
    }
    NSString* key =  [self getTextureId:player];
    id _timeObserverId = _timeObserverIdDict[key];
    [_timeObserverIdDict removeObjectForKey: key];
    [_artworkImageDict removeObjectForKey:key];
    if (_timeObserverId){
        [player.player removeTimeObserver:_timeObserverId];
        _timeObserverId = nil;
    }
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo =  @{};
}

- (void) stopOtherUpdateListener: (BetterPlayer*) player{
    NSString* currentPlayerTextureId = [self getTextureId:player];
    for (NSString* textureId in _timeObserverIdDict.allKeys) {
        if (currentPlayerTextureId == textureId){
            continue;
        }

        id timeObserverId = [_timeObserverIdDict objectForKey:textureId];
        BetterPlayer* playerToRemoveListener = [_players objectForKey:textureId];
        [playerToRemoveListener.player removeTimeObserver: timeObserverId];
    }
    [_timeObserverIdDict removeAllObjects];

}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {


    if ([@"init" isEqualToString:call.method]) {
        // Allow audio playback when the Ring/Silent switch is set to silent
        for (NSNumber* textureId in _players) {
            [_players[textureId] dispose];
        }

        [_players removeAllObjects];
        result(nil);
    } else if ([@"create" isEqualToString:call.method]) {
        BetterPlayer* player = [[BetterPlayer alloc] initWithFrame:CGRectZero];
        [self onPlayerSetup:player result:result];
    } else {
        NSDictionary* argsMap = call.arguments;
        int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
        BetterPlayer* player = _players[@(textureId)];
        if ([@"setDataSource" isEqualToString:call.method]) {
            [player clear];
            // This call will clear cached frame because we will return transparent frame

            NSDictionary* dataSource = argsMap[@"dataSource"];
            [_dataSourceDict setObject:dataSource forKey:[self getTextureId:player]];
            NSString* assetArg = dataSource[@"asset"];
            NSString* uriArg = dataSource[@"uri"];
            NSString* key = dataSource[@"key"];
            NSString* certificateUrl = dataSource[@"certificateUrl"];
            NSString* licenseUrl = dataSource[@"licenseUrl"];
            NSDictionary* headers = dataSource[@"headers"];
            NSString* cacheKey = dataSource[@"cacheKey"];
            NSNumber* maxCacheSize = dataSource[@"maxCacheSize"];
            NSString* videoExtension = dataSource[@"videoExtension"];
            
            int overriddenDuration = 0;
            if ([dataSource objectForKey:@"overriddenDuration"] != [NSNull null]){
                overriddenDuration = [dataSource[@"overriddenDuration"] intValue];
            }

            BOOL useCache = false;
            id useCacheObject = [dataSource objectForKey:@"useCache"];
            if (useCacheObject != [NSNull null]) {
                useCache = [[dataSource objectForKey:@"useCache"] boolValue];
                if (useCache){
                    [_cacheManager setMaxCacheSize:maxCacheSize];
                }
            }

            if (headers == [NSNull null] || headers == NULL){
                headers = @{};
            }

            if (assetArg) {
                NSString* assetPath;
                NSString* package = dataSource[@"package"];
                if (![package isEqual:[NSNull null]]) {
                    assetPath = [_registrar lookupKeyForAsset:assetArg fromPackage:package];
                } else {
                    assetPath = [_registrar lookupKeyForAsset:assetArg];
                }
                [player setDataSourceAsset:assetPath withKey:key withCertificateUrl:certificateUrl withLicenseUrl: licenseUrl cacheKey:cacheKey cacheManager:_cacheManager overriddenDuration:overriddenDuration];
            } else if (uriArg) {
                [player setDataSourceURL:[NSURL URLWithString:uriArg] withKey:key withCertificateUrl:certificateUrl withLicenseUrl: licenseUrl withHeaders:headers withCache: useCache cacheKey:cacheKey cacheManager:_cacheManager overriddenDuration:overriddenDuration videoExtension: videoExtension];
            } else {
                result(FlutterMethodNotImplemented);
            }
            result(nil);
        } else if ([@"dispose" isEqualToString:call.method]) {
            [player clear];
            [self disposeNotificationData:player];
            [self setRemoteCommandsNotificationNotActive];
            [_players removeObjectForKey:@(textureId)];
            // If the Flutter contains https://github.com/flutter/engine/pull/12695,
            // the `player` is disposed via `onTextureUnregistered` at the right time.
            // Without https://github.com/flutter/engine/pull/12695, there is no guarantee that the
            // texture has completed the un-reregistration. It may leads a crash if we dispose the
            // `player` before the texture is unregistered. We add a dispatch_after hack to make sure the
            // texture is unregistered before we dispose the `player`.
            //
            // TODO(cyanglaz): Remove this dispatch block when
            // https://github.com/flutter/flutter/commit/8159a9906095efc9af8b223f5e232cb63542ad0b is in
            // stable And update the min flutter version of the plugin to the stable version.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                if (!player.disposed) {
                    [player dispose];
                }
            });
            if ([_players count] == 0) {
                [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
            }
            result(nil);
        } else if ([@"setLooping" isEqualToString:call.method]) {
            [player setIsLooping:[argsMap[@"looping"] boolValue]];
            result(nil);
        } else if ([@"setVolume" isEqualToString:call.method]) {
            [player setVolume:[argsMap[@"volume"] doubleValue]];
            result(nil);
        } else if ([@"play" isEqualToString:call.method]) {
            [self setupRemoteNotification:player];
            [player play];
            result(nil);
        } else if ([@"position" isEqualToString:call.method]) {
            result(@([player position]));
        } else if ([@"absolutePosition" isEqualToString:call.method]) {
            result(@([player absolutePosition]));
        } else if ([@"seekTo" isEqualToString:call.method]) {
            [player seekTo:[argsMap[@"location"] intValue]];
            result(nil);
        } else if ([@"pause" isEqualToString:call.method]) {
            [player pause];
            result(nil);
        } else if ([@"setSpeed" isEqualToString:call.method]) {
            [player setSpeed:[[argsMap objectForKey:@"speed"] doubleValue] result:result];
        }else if ([@"setTrackParameters" isEqualToString:call.method]) {
            int width = [argsMap[@"width"] intValue];
            int height = [argsMap[@"height"] intValue];
            int bitrate = [argsMap[@"bitrate"] intValue];

            [player setTrackParameters:width: height : bitrate];
            result(nil);
        } else if ([@"enablePictureInPicture" isEqualToString:call.method]){
            double left = [argsMap[@"left"] doubleValue];
            double top = [argsMap[@"top"] doubleValue];
            double width = [argsMap[@"width"] doubleValue];
            double height = [argsMap[@"height"] doubleValue];
            [player enablePictureInPicture:CGRectMake(left, top, width, height)];
        } else if ([@"isPictureInPictureSupported" isEqualToString:call.method]){
            if (@available(iOS 9.0, *)){
                if ([AVPictureInPictureController isPictureInPictureSupported]){
                    result([NSNumber numberWithBool:true]);
                    return;
                }
            }

            result([NSNumber numberWithBool:false]);
        } else if ([@"disablePictureInPicture" isEqualToString:call.method]){
            [player disablePictureInPicture];
            [player setPictureInPicture:false];
        } else if ([@"setAudioTrack" isEqualToString:call.method]){
            NSString* name = argsMap[@"name"];
            int index = [argsMap[@"index"] intValue];
            [player setAudioTrack:name index: index];
        } else if ([@"setMixWithOthers" isEqualToString:call.method]){
            [player setMixWithOthers:[argsMap[@"mixWithOthers"] boolValue]];
        } else if ([@"preCache" isEqualToString:call.method]){
            NSDictionary* dataSource = argsMap[@"dataSource"];
            NSString* urlArg = dataSource[@"uri"];
            NSString* cacheKey = dataSource[@"cacheKey"];
            NSDictionary* headers = dataSource[@"headers"];
            NSNumber* maxCacheSize = dataSource[@"maxCacheSize"];
            NSString* videoExtension = dataSource[@"videoExtension"];
            
            if (headers == [ NSNull null ]){
                headers = @{};
            }
            if (videoExtension == [NSNull null]){
                videoExtension = nil;
            }
            
            if (urlArg != [NSNull null]){
                NSURL* url = [NSURL URLWithString:urlArg];
                if ([_cacheManager isPreCacheSupportedWithUrl:url videoExtension:videoExtension]){
                    [_cacheManager setMaxCacheSize:maxCacheSize];
                    [_cacheManager preCacheURL:url cacheKey:cacheKey videoExtension:videoExtension withHeaders:headers completionHandler:^(BOOL success){
                    }];
                } else {
                    NSLog(@"Pre cache is not supported for given data source.");
                }
            }
            result(nil);
        } else if ([@"clearCache" isEqualToString:call.method]){
            [_cacheManager clearCache];
            result(nil);
        } else if ([@"stopPreCache" isEqualToString:call.method]){
            NSString* urlArg = argsMap[@"url"];
            NSString* cacheKey = argsMap[@"cacheKey"];
            NSString* videoExtension = argsMap[@"videoExtension"];
            if (urlArg != [NSNull null]){
                NSURL* url = [NSURL URLWithString:urlArg];
                if ([_cacheManager isPreCacheSupportedWithUrl:url videoExtension:videoExtension]){
                    [_cacheManager stopPreCache:url cacheKey:cacheKey
                              completionHandler:^(BOOL success){
                    }];
                } else {
                    NSLog(@"Stop pre cache is not supported for given data source.");
                }
            }
            result(nil);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
}
@end
