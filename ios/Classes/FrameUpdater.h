//
//  FrameUpdater.h
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, weak, readonly) NSObject<FlutterTextureRegistry>* registry;
- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry;
- (void)onDisplayLink:(CADisplayLink*)link;
@end

NS_ASSUME_NONNULL_END
