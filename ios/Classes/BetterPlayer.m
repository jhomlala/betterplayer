// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BetterPlayer.h"
#import <better_player/better_player-Swift.h>

static void* timeRangeContext = &timeRangeContext;
static void* statusContext = &statusContext;
static void* playbackLikelyToKeepUpContext = &playbackLikelyToKeepUpContext;
static void* playbackBufferEmptyContext = &playbackBufferEmptyContext;
static void* playbackBufferFullContext = &playbackBufferFullContext;
static void* presentationSizeContext = &presentationSizeContext;


#if TARGET_OS_IOS
void (^__strong _Nonnull _restoreUserInterfaceForPIPStopCompletionHandler)(BOOL);
API_AVAILABLE(ios(9.0))
AVPictureInPictureController *_pipController;
#endif

@implementation BetterPlayer
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _isInitialized = false;
    _isPlaying = false;
    _disposed = false;
    _player = [[AVPlayer alloc] init];
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    ///Fix for loading large videos
    if (@available(iOS 10.0, *)) {
        _player.automaticallyWaitsToMinimizeStalling = false;
    }
    self._observersAdded = false;
    return self;
}

- (nonnull UIView *)view {
    BetterPlayerView *playerView = [[BetterPlayerView alloc] initWithFrame:CGRectZero];
    playerView.player = _player;
    return playerView;
}

- (void)addObservers:(AVPlayerItem*)item {
    if (!self._observersAdded){
        [_player addObserver:self forKeyPath:@"rate" options:0 context:nil];
        [item addObserver:self forKeyPath:@"loadedTimeRanges" options:0 context:timeRangeContext];
        [item addObserver:self forKeyPath:@"status" options:0 context:statusContext];
        [item addObserver:self forKeyPath:@"presentationSize" options:0 context:presentationSizeContext];
        [item addObserver:self
               forKeyPath:@"playbackLikelyToKeepUp"
                  options:0
                  context:playbackLikelyToKeepUpContext];
        [item addObserver:self
               forKeyPath:@"playbackBufferEmpty"
                  options:0
                  context:playbackBufferEmptyContext];
        [item addObserver:self
               forKeyPath:@"playbackBufferFull"
                  options:0
                  context:playbackBufferFullContext];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidPlayToEndTime:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:item];
        self._observersAdded = true;
    }
}

- (void)clear {
    _isInitialized = false;
    _isPlaying = false;
    _disposed = false;
    _failedCount = 0;
    _key = nil;
    if (_player.currentItem == nil) {
        return;
    }

    if (_player.currentItem == nil) {
        return;
    }

    [self removeObservers];
    AVAsset* asset = [_player.currentItem asset];
    [asset cancelLoading];
}

- (void) removeObservers{
    if (self._observersAdded){
        [_player removeObserver:self forKeyPath:@"rate" context:nil];
        [[_player currentItem] removeObserver:self forKeyPath:@"status" context:statusContext];
        [[_player currentItem] removeObserver:self forKeyPath:@"presentationSize" context:presentationSizeContext];
        [[_player currentItem] removeObserver:self
                                   forKeyPath:@"loadedTimeRanges"
                                      context:timeRangeContext];
        [[_player currentItem] removeObserver:self
                                   forKeyPath:@"playbackLikelyToKeepUp"
                                      context:playbackLikelyToKeepUpContext];
        [[_player currentItem] removeObserver:self
                                   forKeyPath:@"playbackBufferEmpty"
                                      context:playbackBufferEmptyContext];
        [[_player currentItem] removeObserver:self
                                   forKeyPath:@"playbackBufferFull"
                                      context:playbackBufferFullContext];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self._observersAdded = false;
    }
}

- (void)itemDidPlayToEndTime:(NSNotification*)notification {
    if (_isLooping) {
        AVPlayerItem* p = [notification object];
        [p seekToTime:kCMTimeZero completionHandler:nil];
    } else {
        if (_eventSink) {
            _eventSink(@{@"event" : @"completed", @"key" : _key});
            [ self removeObservers];

        }
    }
}


static inline CGFloat radiansToDegrees(CGFloat radians) {
    // Input range [-pi, pi] or [-180, 180]
    CGFloat degrees = GLKMathRadiansToDegrees((float)radians);
    if (degrees < 0) {
        // Convert -90 to 270 and -180 to 180
        return degrees + 360;
    }
    // Output degrees in between [0, 360[
    return degrees;
};

- (void)setDataSourceAsset:(NSString*)asset withKey:(NSString*)key withCertificateUrl:(NSString*)certificateUrl withLicenseUrl:(NSString*)licenseUrl cacheKey:(NSString*)cacheKey cacheManager:(CacheManager*)cacheManager overriddenDuration:(int) overriddenDuration{
    NSString* path = [[NSBundle mainBundle] pathForResource:asset ofType:nil];
    return [self setDataSourceURL:[NSURL fileURLWithPath:path] withKey:key withCertificateUrl:certificateUrl withLicenseUrl:(NSString*)licenseUrl withHeaders: @{} withCache: false cacheKey:cacheKey cacheManager:cacheManager overriddenDuration:overriddenDuration videoExtension: nil];
}

- (void)setDataSourceURL:(NSURL*)url withKey:(NSString*)key withCertificateUrl:(NSString*)certificateUrl withLicenseUrl:(NSString*)licenseUrl withHeaders:(NSDictionary*)headers withCache:(BOOL)useCache cacheKey:(NSString*)cacheKey cacheManager:(CacheManager*)cacheManager overriddenDuration:(int) overriddenDuration videoExtension: (NSString*) videoExtension{
    _overriddenDuration = 0;
    if (headers == [NSNull null] || headers == NULL){
        headers = @{};
    }
    
    AVPlayerItem* item;
    if (useCache){
        if (cacheKey == [NSNull null]){
            cacheKey = nil;
        }
        if (videoExtension == [NSNull null]){
            videoExtension = nil;
        }
        
        item = [cacheManager getCachingPlayerItemForNormalPlayback:url cacheKey:cacheKey videoExtension: videoExtension headers:headers];
    } else {
        AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url
                                                options:@{@"AVURLAssetHTTPHeaderFieldsKey" : headers}];
        if (certificateUrl && certificateUrl != [NSNull null] && [certificateUrl length] > 0) {
            NSURL * certificateNSURL = [[NSURL alloc] initWithString: certificateUrl];
            NSURL * licenseNSURL = [[NSURL alloc] initWithString: licenseUrl];
            _loaderDelegate = [[BetterPlayerEzDrmAssetsLoaderDelegate alloc] init:certificateNSURL withLicenseURL:licenseNSURL];
            dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, -1);
            dispatch_queue_t streamQueue = dispatch_queue_create("streamQueue", qos);
            [asset.resourceLoader setDelegate:_loaderDelegate queue:streamQueue];
        }
        item = [AVPlayerItem playerItemWithAsset:asset];
    }

    if (@available(iOS 10.0, *) && overriddenDuration > 0) {
        _overriddenDuration = overriddenDuration;
    }
    return [self setDataSourcePlayerItem:item withKey:key];
}

- (void)setDataSourcePlayerItem:(AVPlayerItem*)item withKey:(NSString*)key{
    _key = key;
    _stalledCount = 0;
    _isStalledCheckStarted = false;
    _playerRate = 1;
    [_player replaceCurrentItemWithPlayerItem:item];
    [self addObservers:item];
}

-(void)handleStalled {
    if (_isStalledCheckStarted){
        return;
    }
   _isStalledCheckStarted = true;
    [self startStalledCheck];
}

-(void)startStalledCheck{
    if (_player.currentItem.playbackLikelyToKeepUp ||
        [self availableDuration] - CMTimeGetSeconds(_player.currentItem.currentTime) > 10.0) {
        [self play];
    } else {
        _stalledCount++;
        if (_stalledCount > 60){
            if (_eventSink != nil) {
                _eventSink([FlutterError
                        errorWithCode:@"VideoError"
                        message:@"Failed to load video: playback stalled"
                        details:nil]);
            }
            return;
        }
        [self performSelector:@selector(startStalledCheck) withObject:nil afterDelay:1];

    }
}

- (NSTimeInterval) availableDuration
{
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    if (loadedTimeRanges.count > 0){
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval result = startSeconds + durationSeconds;
        return result;
    } else {
        return 0;
    }

}

- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {

    if ([path isEqualToString:@"rate"]) {
        if (@available(iOS 10.0, *)) {
            if (_pipController.pictureInPictureActive == true){
                if (_lastAvPlayerTimeControlStatus != [NSNull null] && _lastAvPlayerTimeControlStatus == _player.timeControlStatus){
                    return;
                }

                if (_player.timeControlStatus == AVPlayerTimeControlStatusPaused){
                    _lastAvPlayerTimeControlStatus = _player.timeControlStatus;
                    if (_eventSink != nil) {
                      _eventSink(@{@"event" : @"pause"});
                    }
                    return;

                }
                if (_player.timeControlStatus == AVPlayerTimeControlStatusPlaying){
                    _lastAvPlayerTimeControlStatus = _player.timeControlStatus;
                    if (_eventSink != nil) {
                      _eventSink(@{@"event" : @"play"});
                    }
                }
            }
        }

        if (_player.rate == 0 && //if player rate dropped to 0
            CMTIME_COMPARE_INLINE(_player.currentItem.currentTime, >, kCMTimeZero) && //if video was started
            CMTIME_COMPARE_INLINE(_player.currentItem.currentTime, <, _player.currentItem.duration) && //but not yet finished
            _isPlaying) { //instance variable to handle overall state (changed to YES when user triggers playback)
            [self handleStalled];
        }
    }

    if (context == timeRangeContext) {
        if (_eventSink != nil) {
            NSMutableArray<NSArray<NSNumber*>*>* values = [[NSMutableArray alloc] init];
            for (NSValue* rangeValue in [object loadedTimeRanges]) {
                CMTimeRange range = [rangeValue CMTimeRangeValue];
                int64_t start = [BetterPlayerTimeUtils FLTCMTimeToMillis:(range.start)];
                int64_t end = start + [BetterPlayerTimeUtils FLTCMTimeToMillis:(range.duration)];
                if (!CMTIME_IS_INVALID(_player.currentItem.forwardPlaybackEndTime)) {
                    int64_t endTime = [BetterPlayerTimeUtils FLTCMTimeToMillis:(_player.currentItem.forwardPlaybackEndTime)];
                    if (end > endTime){
                        end = endTime;
                    }
                }

                [values addObject:@[ @(start), @(end) ]];
            }
            _eventSink(@{@"event" : @"bufferingUpdate", @"values" : values, @"key" : _key});
        }
    }
    else if (context == presentationSizeContext){
        [self onReadyToPlay];
    }

    else if (context == statusContext) {
        AVPlayerItem* item = (AVPlayerItem*)object;
        switch (item.status) {
            case AVPlayerItemStatusFailed:
                NSLog(@"Failed to load video:");
                NSLog(item.error.debugDescription);

                if (_eventSink != nil) {
                    _eventSink([FlutterError
                                errorWithCode:@"VideoError"
                                message:[@"Failed to load video: "
                                         stringByAppendingString:[item.error localizedDescription]]
                                details:nil]);
                }
                break;
            case AVPlayerItemStatusUnknown:
                break;
            case AVPlayerItemStatusReadyToPlay:
                [self onReadyToPlay];
                break;
        }
    } else if (context == playbackLikelyToKeepUpContext) {
        if ([[_player currentItem] isPlaybackLikelyToKeepUp]) {
            [self updatePlayingState];
            if (_eventSink != nil) {
                _eventSink(@{@"event" : @"bufferingEnd", @"key" : _key});
            }
        }
    } else if (context == playbackBufferEmptyContext) {
        if (_eventSink != nil) {
            _eventSink(@{@"event" : @"bufferingStart", @"key" : _key});
        }
    } else if (context == playbackBufferFullContext) {
        if (_eventSink != nil) {
            _eventSink(@{@"event" : @"bufferingEnd", @"key" : _key});
        }
    }
}

- (void)updatePlayingState {
    if (!_isInitialized || !_key) {
        return;
    }
    if (!self._observersAdded){
        [self addObservers:[_player currentItem]];
    }

    if (_isPlaying) {
        if (@available(iOS 10.0, *)) {
            [_player playImmediatelyAtRate:1.0];
            _player.rate = _playerRate;
        } else {
            [_player play];
            _player.rate = _playerRate;
        }
    } else {
        [_player pause];
    }
}

- (void)onReadyToPlay {
    if (_eventSink && !_isInitialized && _key) {
        if (!_player.currentItem) {
            return;
        }
        if (_player.status != AVPlayerStatusReadyToPlay) {
            return;
        }

        CGSize size = [_player currentItem].presentationSize;
        CGFloat width = size.width;
        CGFloat height = size.height;


        AVAsset *asset = _player.currentItem.asset;
        bool onlyAudio =  [[asset tracksWithMediaType:AVMediaTypeVideo] count] == 0;

        // The player has not yet initialized.
        if (!onlyAudio && height == CGSizeZero.height && width == CGSizeZero.width) {
            return;
        }
        const BOOL isLive = CMTIME_IS_INDEFINITE([_player currentItem].duration);
        // The player may be initialized but still needs to determine the duration.
        if (isLive == false && [self duration] == 0) {
            return;
        }

        //Fix from https://github.com/flutter/flutter/issues/66413
        AVPlayerItemTrack *track = [self.player currentItem].tracks.firstObject;
        CGSize naturalSize = track.assetTrack.naturalSize;
        CGAffineTransform prefTrans = track.assetTrack.preferredTransform;
        CGSize realSize = CGSizeApplyAffineTransform(naturalSize, prefTrans);

        int64_t duration = [BetterPlayerTimeUtils FLTCMTimeToMillis:(_player.currentItem.asset.duration)];
        if (_overriddenDuration > 0 && duration > _overriddenDuration){
            _player.currentItem.forwardPlaybackEndTime = CMTimeMake(_overriddenDuration/1000, 1);
        }

        _isInitialized = true;
        [self updatePlayingState];
        _eventSink(@{
            @"event" : @"initialized",
            @"duration" : @([self duration]),
            @"width" : @(fabs(realSize.width) ? : width),
            @"height" : @(fabs(realSize.height) ? : height),
            @"key" : _key
        });
    }
}

- (void)play {
    _stalledCount = 0;
    _isStalledCheckStarted = false;
    _isPlaying = true;
    [self updatePlayingState];
}

- (void)pause {
    _isPlaying = false;
    [self updatePlayingState];
}

- (int64_t)position {
    return [BetterPlayerTimeUtils FLTCMTimeToMillis:([_player currentTime])];
}

- (int64_t)absolutePosition {
    return [BetterPlayerTimeUtils FLTNSTimeIntervalToMillis:([[[_player currentItem] currentDate] timeIntervalSince1970])];
}

- (int64_t)duration {
    CMTime time;
    if (@available(iOS 13, *)) {
        time =  [[_player currentItem] duration];
    } else {
        time =  [[[_player currentItem] asset] duration];
    }
    if (!CMTIME_IS_INVALID(_player.currentItem.forwardPlaybackEndTime)) {
        time = [[_player currentItem] forwardPlaybackEndTime];
    }

    return [BetterPlayerTimeUtils FLTCMTimeToMillis:(time)];
}

- (void)seekTo:(int)location {
    ///When player is playing, pause video, seek to new position and start again. This will prevent issues with seekbar jumps.
    bool wasPlaying = _isPlaying;
    if (wasPlaying){
        [_player pause];
    }

    [_player seekToTime:CMTimeMake(location, 1000)
        toleranceBefore:kCMTimeZero
         toleranceAfter:kCMTimeZero
      completionHandler:^(BOOL finished){
        if (wasPlaying){
            _player.rate = _playerRate;
        }
    }];
}

- (void)setIsLooping:(bool)isLooping {
    _isLooping = isLooping;
}

- (void)setVolume:(double)volume {
    _player.volume = (float)((volume < 0.0) ? 0.0 : ((volume > 1.0) ? 1.0 : volume));
}

- (void)setSpeed:(double)speed result:(FlutterResult)result {
    if (speed == 1.0 || speed == 0.0) {
        _playerRate = 1;
        result(nil);
    } else if (speed < 0 || speed > 2.0) {
        result([FlutterError errorWithCode:@"unsupported_speed"
                                   message:@"Speed must be >= 0.0 and <= 2.0"
                                   details:nil]);
    } else if ((speed > 1.0 && _player.currentItem.canPlayFastForward) ||
               (speed < 1.0 && _player.currentItem.canPlaySlowForward)) {
        _playerRate = speed;
        result(nil);
    } else {
        if (speed > 1.0) {
            result([FlutterError errorWithCode:@"unsupported_fast_forward"
                                       message:@"This video cannot be played fast forward"
                                       details:nil]);
        } else {
            result([FlutterError errorWithCode:@"unsupported_slow_forward"
                                       message:@"This video cannot be played slow forward"
                                       details:nil]);
        }
    }

    if (_isPlaying){
        _player.rate = _playerRate;
    }
}


- (void)setTrackParameters:(int) width: (int) height: (int)bitrate {
    _player.currentItem.preferredPeakBitRate = bitrate;
    if (@available(iOS 11.0, *)) {
        if (width == 0 && height == 0){
            _player.currentItem.preferredMaximumResolution = CGSizeZero;
        } else {
            _player.currentItem.preferredMaximumResolution = CGSizeMake(width, height);
        }
    }
}

- (void)setPictureInPicture:(BOOL)pictureInPicture
{
    self._pictureInPicture = pictureInPicture;
    if (@available(iOS 9.0, *)) {
        if (_pipController && self._pictureInPicture && ![_pipController isPictureInPictureActive]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_pipController startPictureInPicture];
            });
        } else if (_pipController && !self._pictureInPicture && [_pipController isPictureInPictureActive]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_pipController stopPictureInPicture];
            });
        } else {
            // Fallback on earlier versions
        } }
}

#if TARGET_OS_IOS
- (void)setRestoreUserInterfaceForPIPStopCompletionHandler:(BOOL)restore
{
    if (_restoreUserInterfaceForPIPStopCompletionHandler != NULL) {
        _restoreUserInterfaceForPIPStopCompletionHandler(restore);
        _restoreUserInterfaceForPIPStopCompletionHandler = NULL;
    }
}

- (void)setupPipController {
    if (@available(iOS 9.0, *)) {
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        if (!_pipController && self._playerLayer && [AVPictureInPictureController isPictureInPictureSupported]) {
            _pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self._playerLayer];
            _pipController.delegate = self;
        }
    } else {
        // Fallback on earlier versions
    }
}

- (void) enablePictureInPicture: (CGRect) frame{
    [self disablePictureInPicture];
    [self usePlayerLayer:frame];
}

- (void)usePlayerLayer: (CGRect) frame
{
    if( _player )
    {
        // Create new controller passing reference to the AVPlayerLayer
        self._playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        UIViewController* vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        self._playerLayer.frame = frame;
        self._playerLayer.needsDisplayOnBoundsChange = YES;
        //  [self._playerLayer addObserver:self forKeyPath:readyForDisplayKeyPath options:NSKeyValueObservingOptionNew context:nil];
        [vc.view.layer addSublayer:self._playerLayer];
        vc.view.layer.needsDisplayOnBoundsChange = YES;
        if (@available(iOS 9.0, *)) {
            _pipController = NULL;
        }
        [self setupPipController];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self setPictureInPicture:true];
        });
    }
}

- (void)disablePictureInPicture
{
    [self setPictureInPicture:true];
    if (__playerLayer){
        [self._playerLayer removeFromSuperlayer];
        self._playerLayer = nil;
        if (_eventSink != nil) {
            _eventSink(@{@"event" : @"pipStop"});
        }
    }
}
#endif

#if TARGET_OS_IOS
- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController  API_AVAILABLE(ios(9.0)){
    [self disablePictureInPicture];
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController  API_AVAILABLE(ios(9.0)){
    if (_eventSink != nil) {
        _eventSink(@{@"event" : @"pipStart"});
    }
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController  API_AVAILABLE(ios(9.0)){

}

- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {

}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error {

}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    [self setRestoreUserInterfaceForPIPStopCompletionHandler: true];
}

- (void) setAudioTrack:(NSString*) name index:(int) index{
    AVMediaSelectionGroup *audioSelectionGroup = [[[_player currentItem] asset] mediaSelectionGroupForMediaCharacteristic: AVMediaCharacteristicAudible];
    NSArray* options = audioSelectionGroup.options;


    for (int audioTrackIndex = 0; audioTrackIndex < [options count]; audioTrackIndex++) {
        AVMediaSelectionOption* option = [options objectAtIndex:audioTrackIndex];
        NSArray *metaDatas = [AVMetadataItem metadataItemsFromArray:option.commonMetadata withKey:@"title" keySpace:@"comn"];
        if (metaDatas.count > 0) {
            NSString *title = ((AVMetadataItem*)[metaDatas objectAtIndex:0]).stringValue;
            if ([name compare:title] == NSOrderedSame && audioTrackIndex == index ){
                [[_player currentItem] selectMediaOption:option inMediaSelectionGroup: audioSelectionGroup];
            }
        }

    }

}

- (void)setMixWithOthers:(bool)mixWithOthers {
  if (mixWithOthers) {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                           error:nil];
  } else {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
  }
}


#endif

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
    _eventSink = events;
    // TODO(@recastrodiaz): remove the line below when the race condition is resolved:
    // https://github.com/flutter/flutter/issues/21483
    // This line ensures the 'initialized' event is sent when the event
    // 'AVPlayerItemStatusReadyToPlay' fires before _eventSink is set (this function
    // onListenWithArguments is called)
    [self onReadyToPlay];
    return nil;
}

/// This method allows you to dispose without touching the event channel.  This
/// is useful for the case where the Engine is in the process of deconstruction
/// so the channel is going to die or is already dead.
- (void)disposeSansEventChannel {
    @try{
        [self clear];
    }
    @catch(NSException *exception) {
        NSLog(exception.debugDescription);
    }
}

- (void)dispose {
    [self pause];
    [self disposeSansEventChannel];
    [_eventChannel setStreamHandler:nil];
    [self disablePictureInPicture];
    [self setPictureInPicture:false];
    _disposed = true;
}

@end
