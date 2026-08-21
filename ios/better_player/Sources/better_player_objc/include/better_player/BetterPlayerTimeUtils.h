// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BetterPlayerTimeUtils : NSObject

+ (int64_t) FLTCMTimeToMillis:(CMTime) time;
+ (int64_t) FLTNSTimeIntervalToMillis:(NSTimeInterval) interval;

@end

NS_ASSUME_NONNULL_END
