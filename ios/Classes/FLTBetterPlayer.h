//
//  FLTBetterPlayer.h
//  better_player
//
//  Created by Koldo on 17/05/2021.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <KTVHTTPCache/KTVHTTPCache.h>
#import <GLKit/GLKit.h>
#import "BetterPlayerTimeUtils.h"
#import "FLTBetterPlayerView.h"
#import "FLTEzdrmAssetsLoaderDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLTBetterPlayer : NSObject <FlutterPlatformView, FlutterStreamHandler, AVPictureInPictureControllerDelegate>
@property(readonly, nonatomic) AVPlayer* player;
@property(readonly, nonatomic) FLTEzdrmAssetsLoaderDelegate* loaderDelegate;
@property(nonatomic) FlutterEventChannel* eventChannel;
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic) CGAffineTransform preferredTransform;
@property(nonatomic, readonly) bool disposed;
@property(nonatomic, readonly) bool isPlaying;
@property(nonatomic) bool isLooping;
@property(nonatomic, readonly) bool isInitialized;
@property(nonatomic, readonly) NSString* key;
@property(nonatomic, readonly) int failedCount;
@property(nonatomic) AVPlayerLayer* _playerLayer;
@property(nonatomic) bool _pictureInPicture;
@property(nonatomic) bool _observersAdded;
@property(nonatomic) int stalledCount;
@property(nonatomic) bool isStalledCheckStarted;
@property(nonatomic) float playerRate;
- (void)play;
- (void)pause;
- (void)setIsLooping:(bool)isLooping;
- (void)updatePlayingState;
- (int64_t) duration;
- (int64_t) position;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setMixWithOthers:(bool)mixWithOthers;
- (void)seekTo:(int)location;
- (void)setDataSourceAsset:(NSString*)asset withKey:(NSString*)key withCertificateUrl:(NSString*)certificateUrl overriddenDuration:(int) overriddenDuration;
- (void)setDataSourceURL:(NSURL*)url withKey:(NSString*)key withCertificateUrl:(NSString*)certificateUrl withHeaders:(NSDictionary*)headers withCache:(BOOL)useCache overriddenDuration:(int) overriddenDuration;
- (void)setVolume:(double)volume;
- (void)setSpeed:(double)speed result:(FlutterResult)result;
- (void) setAudioTrack:(NSString*) name index:(int) index;
- (void)setTrackParameters:(int) width: (int) height: (int)bitrate;
- (void) enablePictureInPicture: (CGRect) frame;
- (void)setPictureInPicture:(BOOL)pictureInPicture;
- (void)disablePictureInPicture;
- (int64_t)absolutePosition;
- (int64_t) FLTCMTimeToMillis:(CMTime) time;

- (void)clear;
- (void)disposeSansEventChannel;
- (void)dispose;
@end

NS_ASSUME_NONNULL_END
