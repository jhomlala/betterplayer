#import "BetterCastFactory.h"


@implementation BetterCastFactory

NSObject<FlutterPluginRegistrar>* _registrar;

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar{
    self = [super init];
    _registrar = registrar;
    return self;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    return [[BetterCastController alloc] initWithFrame:frame viewId:viewId registrar:_registrar];
}

@end
