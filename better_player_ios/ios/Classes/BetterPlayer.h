// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import "BetterPlayerTimeUtils.h"
#import "BetterPlayerView.h"
#import "BetterPlayerEzDrmAssetsLoaderDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class CacheManager;

@interface BetterPlayer : NSObject <FlutterPlatformView, FlutterStreamHandler, AVPictureInPictureControllerDelegate>
@property(readonly, nonatomic) AVPlayer* player;
@property(readonly, nonatomic) BetterPlayerEzDrmAssetsLoaderDelegate* loaderDelegate;
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
@property(nonatomic) int overriddenDuration;
@property(nonatomic) AVPlayerTimeControlStatus lastAvPlayerTimeControlStatus;
- (void)play;
- (void)pause;
- (void)setIsLooping:(bool)isLooping;
- (void)updatePlayingState;
- (int64_t) duration;
- (int64_t) position;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setMixWithOthers:(bool)mixWithOthers;
- (void)seekTo:(int)location;
- (void)setDataSourceAsset:(NSString*)asset withKey:(NSString*)key withCertificateUrl:(NSString*)certificateUrl withLicenseUrl:(NSString*)licenseUrl cacheKey:(NSString*)cacheKey cacheManager:(CacheManager*)cacheManager overriddenDuration:(int) overriddenDuration;
- (void)setDataSourceURL:(NSURL*)url withKey:(NSString*)key withCertificateUrl:(NSString*)certificateUrl withLicenseUrl:(NSString*)licenseUrl withHeaders:(NSDictionary*)headers withCache:(BOOL)useCache cacheKey:(NSString*)cacheKey cacheManager:(CacheManager*)cacheManager overriddenDuration:(int) overriddenDuration videoExtension: (NSString*) videoExtension;
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
