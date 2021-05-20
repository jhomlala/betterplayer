// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BetterPlayerTimeUtils.h"

@implementation BetterPlayerTimeUtils

+ (int64_t) FLTCMTimeToMillis:(CMTime) time {
    if (time.timescale == 0) return 0;
    return time.value * 1000 / time.timescale;
}

+ (int64_t) FLTNSTimeIntervalToMillis:(NSTimeInterval) interval {
    return (int64_t)(interval * 1000.0);
}

@end
