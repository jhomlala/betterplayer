#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <GoogleCast/GoogleCast.h>

@interface BetterCastController: NSObject<FlutterPlatformView>
@property(readonly, nonatomic) FlutterMethodChannel* channel;
@property(readonly, nonatomic) GCKUICastButton* castButton;
@property(readonly, nonatomic) GCKSessionManager* sessionManager;
- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t)viewId registrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end
