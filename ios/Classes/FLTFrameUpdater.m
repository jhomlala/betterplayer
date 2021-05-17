//
//  FLTFrameUpdater.m
//  better_player
//
//  Created by Koldo on 17/05/2021.
//

#import "FLTFrameUpdater.h"

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
