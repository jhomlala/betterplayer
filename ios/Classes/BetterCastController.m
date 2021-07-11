#import "BetterCastController.h"

@implementation BetterCastController

- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t)viewId registrar:(NSObject<FlutterPluginRegistrar>*)registrar{
    
    NSString* channelName = [NSString stringWithFormat:@"flutter_video_cast/chromeCast_%d", viewId];
    NSLog(@"Channel name!!!");
    NSLog(channelName);
    _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:[registrar messenger]];
    _castButton = [[GCKUICastButton alloc] initWithFrame:frame];
    _sessionManager = GCKCastContext.sharedInstance.sessionManager;
    
    [_channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        [self handleMethodCall:call result:result];
    }];
    self = [super init];
    return self;
}

- (nonnull UIView *)view {
    return _castButton;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"chromeCast#click" isEqualToString:call.method]) {
        NSLog(@"Clicked on the button");
        [_castButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    else {
       result(FlutterMethodNotImplemented);
   }
}

@end
