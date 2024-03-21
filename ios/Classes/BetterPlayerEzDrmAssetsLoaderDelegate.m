// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BetterPlayerEzDrmAssetsLoaderDelegate.h"

@implementation BetterPlayerEzDrmAssetsLoaderDelegate

NSString *_assetId;

NSString * DEFAULT_LICENSE_SERVER_URL = @"https://fps.ezdrm.com/api/licenses/";

//MGR: accept drmHeaders from flutter
- (instancetype)init:(NSURL *)certificateURL withLicenseURL:(NSURL *)licenseURL withDrmHeaders:(NSDictionary*)drmHeaders {
    self = [super init];
    _certificateURL = certificateURL;
    _licenseURL = licenseURL;
    //MGR: store drmHeaders received from flutter DRM configuration
    _drmHeaders = drmHeaders;
    return self;
}

/*------------------------------------------
 **
 ** getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest
 **
 ** Takes the bundled SPC and sends it to the license server defined at licenseUrl or KEY_SERVER_URL (if licenseUrl is null).
 ** It returns CKC.
 ** ---------------------------------------*/
- (NSData *)getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:(NSData*)requestBytes and:(NSString *)assetId and:(NSString *)customParams and:(NSError *)errorOut {
    NSData * decodedData;
    NSURLResponse * response;
    
    NSURL * finalLicenseURL;
    if (_licenseURL != [NSNull null]){
        finalLicenseURL = _licenseURL;
    } else {
        finalLicenseURL = [[NSURL alloc] initWithString: DEFAULT_LICENSE_SERVER_URL];
    }
    //NSURL * ksmURL = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@%@",finalLicenseURL,assetId,customParams]];
    //MGR: appending data to URL causes 404 so skip this part; content ID is part of preAuthorization header
    NSURL * ksmURL = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@",finalLicenseURL]];

    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:ksmURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-type"];
    //MGR: set Authorization and PreAuthorization headers in license request
    for(id key in _drmHeaders)
                [request setValue: [_drmHeaders objectForKey:key] forHTTPHeaderField: key];
    [request setHTTPBody:requestBytes];
    
    @try {
        decodedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    }
    @catch (NSException* excp) {
        NSLog(@"SDK Error, SDK responded with Error: (error)");
    }

    //MGR: response is a json with base64 encoded CKC
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:nil];
    NSString *encodedCkc = [json objectForKey: @"CkcMessage"];
    NSData *ckc = [[NSData alloc] initWithBase64EncodedString:encodedCkc options:0];
    NSLog(@"Received CKC %d", ckc.length);

    return ckc;
}

/*------------------------------------------
 **
 ** getAppCertificate
 **
 ** returns the apps certificate for authenticating against your server
 ** the example here uses a local certificate
 ** but you may need to edit this function to point to your certificate
 ** ---------------------------------------*/
- (NSData *)getAppCertificate:(NSString *) String {
    NSData * certificate = nil;
    NSURLResponse * response;
    // certificate = [NSData dataWithContentsOfURL:_certificateURL];
    //MGR: get the certificate from server using DRM headers
    NSURL * certURL = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@",_certificateURL]];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:certURL];
    [request setHTTPMethod:@"GET"];
    //MGR: it is enough to pass Authorization header but be generous and pass all DRM headers :-)
    for(id key in _drmHeaders)
        [request setValue: [_drmHeaders objectForKey:key] forHTTPHeaderField: key];

    @try {
        certificate = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    }
    @catch (NSException* excp) {
        NSLog(@"SDK Error, SDK responded with Error: (error)");
    }
    NSLog(@"Received Certificate %d", certificate.length);
    return certificate;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *assetURI = loadingRequest.request.URL;
    NSString * str = assetURI.absoluteString;
    NSString * mySubstring = [str substringFromIndex:str.length - 36];
    _assetId = mySubstring;
    NSString * scheme = assetURI.scheme;
    NSData * requestBytes;
    NSData * certificate;
    if (!([scheme isEqualToString: @"skd"])){
        return NO;
    }
    @try {
        certificate = [self getAppCertificate:_assetId];
    }
    @catch (NSException* excp) {
        [loadingRequest finishLoadingWithError:[[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorClientCertificateRejected userInfo:nil]];
    }
    @try {
        requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate contentIdentifier: [str dataUsingEncoding:NSUTF8StringEncoding] options:nil error:nil];
    }
    @catch (NSException* excp) {
        [loadingRequest finishLoadingWithError:nil];
        return YES;
    }
    
    NSString * passthruParams = [NSString stringWithFormat:@"?customdata=%@", _assetId];
    NSData * responseData;
    NSError * error;
    
    responseData = [self getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:requestBytes and:_assetId and:passthruParams and:error];
    
    if (responseData != nil && responseData != NULL && ![responseData.class isKindOfClass:NSNull.class]){
        AVAssetResourceLoadingDataRequest * dataRequest = loadingRequest.dataRequest;
        [dataRequest respondWithData:responseData];
        [loadingRequest finishLoading];
    } else {
        [loadingRequest finishLoadingWithError:error];
    }
    
    return YES;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest {
    return [self resourceLoader:resourceLoader shouldWaitForLoadingOfRequestedResource:renewalRequest];
}

@end
