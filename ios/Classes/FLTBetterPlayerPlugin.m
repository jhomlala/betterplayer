// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTBetterPlayerPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <better_player/better_player-Swift.h>

#if !__has_feature(objc_arc)
#error Code Requires ARC.
#endif

int64_t FLTCMTimeToMillis(CMTime time) {
    if (time.timescale == 0) return 0;
    return time.value * 1000 / time.timescale;
}

int64_t FLTNSTimeIntervalToMillis(NSTimeInterval interval) {
    return (int64_t)(interval * 1000.0);
}

@interface FLTFrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, weak, readonly) NSObject<FlutterTextureRegistry>* registry;
- (void)onDisplayLink:(CADisplayLink*)link;
@end

@implementation FLTFrameUpdater
- (FLTFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry {
    NSAssert(self, @"super init cannot be nil");
    if (self == nil) return nil;
    _registry = registry;
    return self;
}

- (void)onDisplayLink:(CADisplayLink*)link {
    [_registry textureFrameAvailable:_textureId];
}
@end

@interface FLTBetterPlayer : NSObject <FlutterTexture, FlutterStreamHandler, AVPictureInPictureControllerDelegate>
@property(readonly, nonatomic) AVPlayer* player;
@property(readonly, nonatomic) AVPlayerItemVideoOutput* videoOutput;
@property(readonly, nonatomic) CADisplayLink* displayLink;
@property(nonatomic) FlutterEventChannel* eventChannel;
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic) CGAffineTransform preferredTransform;
@property(nonatomic, readonly) bool disposed;
@property(nonatomic, readonly) bool isPlaying;
@property(nonatomic) bool isLooping;
@property(nonatomic, readonly) bool isInitialized;
@property(nonatomic, readonly) NSString* key;
@property(nonatomic, readonly) CVPixelBufferRef prevBuffer;
@property(nonatomic, readonly) int failedCount;
@property(nonatomic) AVPlayerLayer* _playerLayer;
@property(nonatomic) bool _pictureInPicture;
@property(nonatomic) bool _observersAdded;
@property(nonatomic) int stalledCount;
@property(nonatomic) bool isStalledCheckStarted;
@property(nonatomic) float playerRate;
@property(nonatomic) AVPlayerTimeControlStatus lastAvPlayerTimeControlStatus;
- (void)play;
- (void)pause;
- (void)setIsLooping:(bool)isLooping;
- (void)updatePlayingState;
- (int64_t) duration;
- (int64_t) position;
@end


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


@implementation FLTBetterPlayer
- (instancetype)initWithFrameUpdater:(FLTFrameUpdater*)frameUpdater {
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
    _displayLink = [CADisplayLink displayLinkWithTarget:frameUpdater
                                               selector:@selector(onDisplayLink:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;
    self._observersAdded = false;
    return self;
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

- (void)removeVideoOutput {
    _videoOutput = nil;
    if (_player.currentItem == nil) {
        return;
    }
    NSArray<AVPlayerItemOutput*>* outputs = [[_player currentItem] outputs];
    for (AVPlayerItemOutput* output in outputs) {
        [[_player currentItem] removeOutput:output];
    }
}

- (void)clear {
    _displayLink.paused = YES;
    _isInitialized = false;
    _isPlaying = false;
    _disposed = false;
    _videoOutput = nil;
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
        [_player pause];
         _isPlaying = false;
         _displayLink.paused = YES;
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

- (AVMutableVideoComposition*)getVideoCompositionWithTransform:(CGAffineTransform)transform
                                                     withAsset:(AVAsset*)asset
                                                withVideoTrack:(AVAssetTrack*)videoTrack {
    AVMutableVideoCompositionInstruction* instruction =
    [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
    AVMutableVideoCompositionLayerInstruction* layerInstruction =
    [AVMutableVideoCompositionLayerInstruction
     videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInstruction setTransform:_preferredTransform atTime:kCMTimeZero];
    
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    instruction.layerInstructions = @[ layerInstruction ];
    videoComposition.instructions = @[ instruction ];
    
    // If in portrait mode, switch the width and height of the video
    CGFloat width = videoTrack.naturalSize.width;
    CGFloat height = videoTrack.naturalSize.height;
    NSInteger rotationDegrees =
    (NSInteger)round(radiansToDegrees(atan2(_preferredTransform.b, _preferredTransform.a)));
    if (rotationDegrees == 90 || rotationDegrees == 270) {
        width = videoTrack.naturalSize.height;
        height = videoTrack.naturalSize.width;
    }
    videoComposition.renderSize = CGSizeMake(width, height);
    
    // TODO(@recastrodiaz): should we use videoTrack.nominalFrameRate ?
    // Currently set at a constant 30 FPS
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    return videoComposition;
}

- (void)addVideoOutput {
    if (_player.currentItem == nil) {
        return;
    }
    
    if (_videoOutput) {
        NSArray<AVPlayerItemOutput*>* outputs = [[_player currentItem] outputs];
        for (AVPlayerItemOutput* output in outputs) {
            if (output == _videoOutput) {
                return;
            }
        }
    }
    
    NSDictionary* pixBuffAttributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferIOSurfacePropertiesKey : @{}
    };
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    [_player.currentItem addOutput:_videoOutput];
}

- (CGAffineTransform)fixTransform:(AVAssetTrack*)videoTrack {
  CGAffineTransform transform = videoTrack.preferredTransform;
  // TODO(@recastrodiaz): why do we need to do this? Why is the preferredTransform incorrect?
  // At least 2 user videos show a black screen when in portrait mode if we directly use the
  // videoTrack.preferredTransform Setting tx to the height of the video instead of 0, properly
  // displays the video https://github.com/flutter/flutter/issues/17606#issuecomment-413473181
  NSInteger rotationDegrees = (NSInteger)round(radiansToDegrees(atan2(transform.b, transform.a)));
  NSLog(@"VIDEO__ %f, %f, %f, %f, %li", transform.tx, transform.ty, videoTrack.naturalSize.height, videoTrack.naturalSize.width, (long)rotationDegrees);
  if (rotationDegrees == 90) {
    transform.tx = videoTrack.naturalSize.height;
    transform.ty = 0;
  } else if (rotationDegrees == 180) {
    transform.tx = videoTrack.naturalSize.width;
    transform.ty = videoTrack.naturalSize.height;
  } else if (rotationDegrees == 270) {
    transform.tx = 0;
    transform.ty = videoTrack.naturalSize.width;
  }
  return transform;
}

- (void)setDataSourceAsset:(NSString*)asset withKey:(NSString*)key cacheKey:(NSString*)cacheKey cacheManager:(CacheManager*)cacheManager overriddenDuration:(int) overriddenDuration{
    NSString* path = [[NSBundle mainBundle] pathForResource:asset ofType:nil];
    return [self setDataSourceURL:[NSURL fileURLWithPath:path] withKey:key withHeaders: @{} withCache: false cacheKey:cacheKey cacheManager:cacheManager overriddenDuration:overriddenDuration];
}

- (void)setDataSourceURL:(NSURL*)url withKey:(NSString*)key withHeaders:(NSDictionary*)headers withCache:(BOOL)useCache cacheKey:(NSString*)cacheKey cacheManager:(CacheManager*)cacheManager overriddenDuration:(int) overriddenDuration{
    if (headers == nil){
        headers = @{};
    }
    AVPlayerItem* item;
    if (useCache) {
        if (cacheKey == nil){
            cacheKey = nil;
        }

        NSLog(@"Cache enabled %@", cacheKey);
        item = [cacheManager getCachingPlayerItemForNormalPlayback:url cacheKey:cacheKey videoExtension: nil headers:headers];
    } else {
        AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url
                                                options:@{@"AVURLAssetHTTPHeaderFieldsKey" : headers}];
        item = [AVPlayerItem playerItemWithAsset:asset];
    }
    
    if (@available(iOS 10.0, *) && overriddenDuration > 0) {
        item.forwardPlaybackEndTime = CMTimeMake(overriddenDuration/1000, 1);
    }
    
    return [self setDataSourcePlayerItem:item withKey:key];
}

- (void)setDataSourcePlayerItem:(AVPlayerItem*)item withKey:(NSString*)key{
    _key = key;
    _stalledCount = 0;
    _isStalledCheckStarted = false;
    _playerRate = 1;
    [_player replaceCurrentItemWithPlayerItem:item];
    
    AVAsset* asset = [item asset];
    void (^assetCompletionHandler)(void) = ^{
        if ([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
            NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if ([tracks count] > 0) {
                AVAssetTrack* videoTrack = tracks[0];
                void (^trackCompletionHandler)(void) = ^{
                    if (self->_disposed) return;
                    if ([videoTrack statusOfValueForKey:@"preferredTransform"
                                                  error:nil] == AVKeyValueStatusLoaded) {
                        // Rotate the video by using a videoComposition and the preferredTransform
                        self->_preferredTransform = [self fixTransform:videoTrack];
                        // Note:
                        // https://developer.apple.com/documentation/avfoundation/avplayeritem/1388818-videocomposition
                        // Video composition can only be used with file-based media and is not supported for
                        // use with media served using HTTP Live Streaming.
                        AVMutableVideoComposition* videoComposition =
                        [self getVideoCompositionWithTransform:self->_preferredTransform
                                                     withAsset:asset
                                                withVideoTrack:videoTrack];
                        item.videoComposition = videoComposition;
                    }
                };
                [videoTrack loadValuesAsynchronouslyForKeys:@[ @"preferredTransform" ]
                                          completionHandler:trackCompletionHandler];
            }
        }
    };
    
    [asset loadValuesAsynchronouslyForKeys:@[ @"tracks" ] completionHandler:assetCompletionHandler];
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
                int64_t start = FLTCMTimeToMillis(range.start);
                int64_t end = start + FLTCMTimeToMillis(range.duration);
                if (!CMTIME_IS_INVALID(_player.currentItem.forwardPlaybackEndTime)) {
                    int64_t endTime = FLTCMTimeToMillis(_player.currentItem.forwardPlaybackEndTime);
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
        _displayLink.paused = YES;
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
    _displayLink.paused = !_isPlaying;
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
        
        _isInitialized = true;
        [self addVideoOutput];
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
    return FLTCMTimeToMillis([_player currentTime]);
}

- (int64_t)absolutePosition {
    return FLTNSTimeIntervalToMillis([[[_player currentItem] currentDate] timeIntervalSince1970]);
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
    
    return FLTCMTimeToMillis(time);
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
            [self->_player play];
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
    
    
    for (int index = 0; index < [options count]; index++) {
        AVMediaSelectionOption* option = [options objectAtIndex:index];
        NSArray *metaDatas = [AVMetadataItem metadataItemsFromArray:option.commonMetadata withKey:@"title" keySpace:@"comn"];
        if (metaDatas.count > 0) {
            NSString *title = ((AVMetadataItem*)[metaDatas objectAtIndex:0]).stringValue;
            if (title == name && index == index ){
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
// This workaround if you will change dataSource. Flutter engine caches CVPixelBufferRef and if you
// return NULL from method copyPixelBuffer Flutter will use cached CVPixelBufferRef. If you will
// change your datasource you can see frame from previeous video. Thats why we should return
// trasparent frame for this situation
- (CVPixelBufferRef)prevTransparentBuffer {
    if (_prevBuffer) {
        CVPixelBufferLockBaseAddress(_prevBuffer, 0);
        
        int bufferWidth = CVPixelBufferGetWidth(_prevBuffer);
        int bufferHeight = CVPixelBufferGetHeight(_prevBuffer);
        unsigned char* pixel = (unsigned char*)CVPixelBufferGetBaseAddress(_prevBuffer);
        
        for (int row = 0; row < bufferHeight; row++) {
            for (int column = 0; column < bufferWidth; column++) {
                pixel[0] = 0;
                pixel[1] = 0;
                pixel[2] = 0;
                pixel[3] = 0;
                pixel += 4;
            }
        }
        CVPixelBufferUnlockBaseAddress(_prevBuffer, 0);
        return _prevBuffer;
    }
    return _prevBuffer;
}


- (CVPixelBufferRef)copyPixelBuffer {
    //Disabled because of black frame issue
    /*if (!_videoOutput || !_isInitialized || !_isPlaying || !_key || ![_player currentItem] ||
     ![[_player currentItem] isPlaybackLikelyToKeepUp]) {
     return [self prevTransparentBuffer];
     }*/
    
    CMTime outputItemTime = [_videoOutput itemTimeForHostTime:CACurrentMediaTime()];
    if ([_videoOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        _failedCount = 0;
        _prevBuffer = [_videoOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        return _prevBuffer;
    } else {
        // AVPlayerItemVideoOutput.hasNewPixelBufferForItemTime doesn't work correctly
        _failedCount++;
        if (_failedCount > 100) {
            _failedCount = 0;
            [self removeVideoOutput];
            [self addVideoOutput];
        }
        return NULL;
    }
}

- (void)onTextureUnregistered {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dispose];
    });
}

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
        [_displayLink invalidate];
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

@interface FLTBetterPlayerPlugin ()
@property(readonly, weak, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, weak, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
@property(readonly, strong, nonatomic) NSMutableDictionary* players;
@property(readonly, strong, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;
@end

@implementation FLTBetterPlayerPlugin
NSMutableDictionary* _dataSourceDict;
NSMutableDictionary*  _timeObserverIdDict;
NSMutableDictionary*  _artworkImageDict;
CacheManager* _cacheManager;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel =
    [FlutterMethodChannel methodChannelWithName:@"better_player_channel"
                                binaryMessenger:[registrar messenger]];
    FLTBetterPlayerPlugin* instance = [[FLTBetterPlayerPlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar publish:instance];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = [registrar textures];
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
        FLTBetterPlayer* player = _players[textureId];
        [player disposeSansEventChannel];
    }
    [_players removeAllObjects];
}

- (void)onPlayerSetup:(FLTBetterPlayer*)player
         frameUpdater:(FLTFrameUpdater*)frameUpdater
               result:(FlutterResult)result {
    int64_t textureId = [_registry registerTexture:player];
    frameUpdater.textureId = textureId;
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

- (void) setupRemoteNotification :(FLTBetterPlayer*) player{
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
    
    if (showNotification){
        [self setRemoteCommandsNotificationActive];
        [self setupRemoteCommands: player];
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


- (void) setupRemoteCommands:(FLTBetterPlayer*)player  {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.togglePlayPauseCommand setEnabled:YES];
    [commandCenter.playCommand setEnabled:YES];
    [commandCenter.pauseCommand setEnabled:YES];
    [commandCenter.nextTrackCommand setEnabled:NO];
    [commandCenter.previousTrackCommand setEnabled:NO];
    if (@available(iOS 9.1, *)) {
        [commandCenter.changePlaybackPositionCommand setEnabled:YES];
    }
    
    [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (player.isPlaying){
            player.eventSink(@{@"event" : @"play"});
        } else {
            player.eventSink(@{@"event" : @"pause"});
            
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.playCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        player.eventSink(@{@"event" : @"play"});
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.pauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        player.eventSink(@{@"event" : @"pause"});
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    
    
    if (@available(iOS 9.1, *)) {
        [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            
            MPChangePlaybackPositionCommandEvent * playbackEvent = (MPChangePlaybackRateCommandEvent * ) event;
            CMTime time = CMTimeMake(playbackEvent.positionTime, 1);
            int64_t millis = FLTCMTimeToMillis(time);
            [player seekTo: millis];
            player.eventSink(@{@"event" : @"seek", @"position": @(millis)});
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
    }
}

- (void) setupRemoteCommandNotification:(FLTBetterPlayer*)player, NSString* title, NSString* author , NSString* imageUrl{
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



- (NSString*) getTextureId: (FLTBetterPlayer*) player{
    NSArray* temp = [_players allKeysForObject: player];
    NSString* key = [temp lastObject];
    return key;
}

- (void) setupUpdateListener:(FLTBetterPlayer*)player,NSString* title, NSString* author,NSString* imageUrl  {
    id _timeObserverId = [player.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time){
        [self setupRemoteCommandNotification:player, title, author, imageUrl];
    }];
    
    NSString* key =  [self getTextureId:player];
    [ _timeObserverIdDict setObject:_timeObserverId forKey: key];
}


- (void) disposeNotificationData: (FLTBetterPlayer*)player{
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

- (void) stopOtherUpdateListener: (FLTBetterPlayer*) player{
    NSString* currentPlayerTextureId = [self getTextureId:player];
    for (NSString* textureId in _timeObserverIdDict.allKeys) {
        if (currentPlayerTextureId == textureId){
            continue;
        }
        
        id timeObserverId = [_timeObserverIdDict objectForKey:textureId];
        FLTBetterPlayer* playerToRemoveListener = [_players objectForKey:textureId];
        [playerToRemoveListener.player removeTimeObserver: timeObserverId];
    }
    [_timeObserverIdDict removeAllObjects];
    
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    
    if ([@"init" isEqualToString:call.method]) {
        // Allow audio playback when the Ring/Silent switch is set to silent
        for (NSNumber* textureId in _players) {
            [_registry unregisterTexture:[textureId unsignedIntegerValue]];
            [_players[textureId] dispose];
        }
        
        [_players removeAllObjects];
        result(nil);
    } else if ([@"create" isEqualToString:call.method]) {
        FLTFrameUpdater* frameUpdater = [[FLTFrameUpdater alloc] initWithRegistry:_registry];
        FLTBetterPlayer* player = [[FLTBetterPlayer alloc] initWithFrameUpdater:frameUpdater];
        [self onPlayerSetup:player frameUpdater:frameUpdater result:result];
    } else {
        NSDictionary* argsMap = call.arguments;
        int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
        FLTBetterPlayer* player = _players[@(textureId)];
        if ([@"setDataSource" isEqualToString:call.method]) {
            [player clear];
            // This call will clear cached frame because we will return transparent frame
            [_registry textureFrameAvailable:textureId];
            
            NSDictionary* dataSource = argsMap[@"dataSource"];
            [_dataSourceDict setObject:dataSource forKey:[self getTextureId:player]];
            NSString* assetArg = dataSource[@"asset"];
            NSString* uriArg = dataSource[@"uri"];
            NSString* key = dataSource[@"key"];
            NSDictionary* headers = dataSource[@"headers"];
            int overriddenDuration = 0;
            if ([dataSource objectForKey:@"overriddenDuration"] != [NSNull null]){
                overriddenDuration = [dataSource[@"overriddenDuration"] intValue];
            }
            
            BOOL useCache = false;
            id useCacheObject = [dataSource objectForKey:@"useCache"];
            if (useCacheObject != [NSNull null]) {
                useCache = [[dataSource objectForKey:@"useCache"] boolValue];

                if (useCache) {
                    NSNumber* maxCacheSize = [NSNumber numberWithInt:100*1024*1024];
                    [_cacheManager setMaxCacheSize:maxCacheSize];
                }
            }
            
            if (headers == nil){
                headers = @{};
            }

            NSString* cacheKey = uriArg;

            if (assetArg) {
                NSString* assetPath;
                NSString* package = dataSource[@"package"];
                if (![package isEqual:[NSNull null]]) {
                    assetPath = [_registrar lookupKeyForAsset:assetArg fromPackage:package];
                } else {
                    assetPath = [_registrar lookupKeyForAsset:assetArg];
                }

                [player setDataSourceAsset:assetPath withKey:key cacheKey:cacheKey cacheManager:_cacheManager overriddenDuration:overriddenDuration];
            } else if (uriArg) {
                [player setDataSourceURL:[NSURL URLWithString:uriArg] withKey:key withHeaders:headers withCache: useCache cacheKey:cacheKey cacheManager:_cacheManager overriddenDuration:overriddenDuration];
            } else {
                result(FlutterMethodNotImplemented);
            }
            result(nil);
        } else if ([@"dispose" isEqualToString:call.method]) {
            [player clear];
            [self disposeNotificationData:player];
            [self setRemoteCommandsNotificationNotActive];
            [_registry unregisterTexture:textureId];
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
        } else if ([@"clearCache" isEqualToString:call.method]){
            //[KTVHTTPCache cacheDeleteAllCaches];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
}
@end
