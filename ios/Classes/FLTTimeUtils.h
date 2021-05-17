//
//  FLTTimeUtils.h
//  better_player
//
//  Created by Koldo on 17/05/2021.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLTTimeUtils : NSObject
+ (int64_t) FLTCMTimeToMillis:(CMTime) time;
+ (int64_t) FLTNSTimeIntervalToMillis:(NSTimeInterval) interval;
@end

NS_ASSUME_NONNULL_END
