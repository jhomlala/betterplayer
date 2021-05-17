//
//  FLTFrameUpdater.h
//  better_player
//
//  Created by Koldo on 17/05/2021.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLTFrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, weak, readonly) NSObject<FlutterTextureRegistry>* registry;
- (void)onDisplayLink:(CADisplayLink*)link;
- (FLTFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END
