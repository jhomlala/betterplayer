//
//  FLTTimeUtils.m
//  better_player
//
//  Created by Koldo on 17/05/2021.
//

#import "FLTTimeUtils.h"

@implementation FLTTimeUtils
+ (int64_t) FLTCMTimeToMillis:(CMTime) time {
    if (time.timescale == 0) return 0;
    return time.value * 1000 / time.timescale;
}

+ (int64_t) FLTNSTimeIntervalToMillis:(NSTimeInterval) interval {
    return (int64_t)(interval * 1000.0);
}
@end
