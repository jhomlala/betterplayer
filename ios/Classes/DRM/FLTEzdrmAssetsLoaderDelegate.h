//
//  FLTEzdrmAssetsLoaderDelegate.h
//  better_player
//
//  Created by Koldo on 18/05/2021.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>


@interface FLTEzdrmAssetsLoaderDelegate : NSObject
@property(readonly, nonatomic) NSURL * certificateURL;
- (instancetype)initWithCertificateUrl:(NSURL *)certificateUrl;
@end

