#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "BetterCastController.h"

@interface BetterCastFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end
