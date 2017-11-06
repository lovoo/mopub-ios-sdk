//
//  InneractiveNativeCustomEvent.m
//  InneractiveAdSample
//
//  Created by Nikita Fedorenko on 28/12/15.
//  Copyright © 2015 Inneractive. All rights reserved.
//

#import "InneractiveNativeCustomEvent.h"
#import "InneractiveCustomEventsKeys.h"

#import <InneractiveAdSDK/InneractiveAdSDK.h>

#import "InneractiveNativeAdAdapter.h"
#import "InneractiveNativeAdRenderer.h"
#import "MPNativeAdRendererConfiguration.h"
#import "InneractiveNativeAdRendererSettings.h"

#import "MPNativeAd.h"
#import "MPNativeAdError.h"
#import "MPNativeAdRequestTargeting.h"

@interface InneractiveNativeCustomEvent () <InneractiveAdDelegate>

@property (nonatomic, strong) InneractiveNativeAdAdapter *adAdapter;
@property (nonatomic, strong) IaNativeAd *nativeAd;

@end

@implementation InneractiveNativeCustomEvent {}

static IaAdType kInneractiveDefaultNativeAdType = IaAdType_InFeedNativeAd;
static NSString * const kInneractiveNativeAdType = @"IANativeAdType";
static const int kInneractiveErrorNoInventory = 1;

#pragma mark - MPNativeCustomEvent

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info {
    NSString *appID = kInneractiveDefaultAppID;
    IaAdType adType = kInneractiveDefaultNativeAdType;
    NSString *keywords = nil;
    
    // get appID and adType from received 'info' dic
    if (info && [info isKindOfClass:NSDictionary.class] && info.count) {
        NSString *receivedAppID = info[kInneractiveAppIDKey];
        
        if (receivedAppID && [receivedAppID isKindOfClass:NSString.class] && receivedAppID.length) {
            appID = receivedAppID;
        }
        
        NSString *receivedKeywords = info[kInneractiveKeywords];
        
        if (receivedKeywords && [receivedKeywords isKindOfClass:NSString.class] && receivedKeywords.length) {
            keywords = receivedKeywords;
        }
        
        NSString *receivedAdType = info[kInneractiveNativeAdType];
        
        if (receivedAdType && [receivedAdType isKindOfClass:NSString.class] && receivedAdType.length) {
            adType = (IaAdType)receivedAdType.integerValue;
            
            if ((adType != IaAdType_NativeAd) && (adType != IaAdType_InFeedNativeAd)) {
                adType = kInneractiveDefaultNativeAdType;
            }
        }
    }
    
    [[InneractiveAdSDK sharedInstance] setAdMediationType:IaAdMediationType_Mopub];
    
    _nativeAd = [[IaNativeAd alloc] initWithAppId:appID adType:adType delegate:self];
    
    if (keywords) {
        self.nativeAd.adConfig.adKeyWords = keywords;
    }
    
    if ([self.delegate respondsToSelector:@selector(targeting)]) {
        MPNativeAdRequestTargeting *targeting = [self.delegate performSelector:@selector(targeting)];
        
        if (targeting && [targeting isKindOfClass:MPNativeAdRequestTargeting.class]) {
            if (targeting.location) {
                self.nativeAd.adConfig.location = targeting.location;
            }
        }
    }
    
    self.nativeAd.adConfig.fullscreenVideoOrientationMode = InneractiveVideoFullscreenOrientationModeMaskAll; // is default;
    
    self.nativeAd.adConfig.nativeAdContentType = IaNativeAdContentTypeImage;
    
    [[InneractiveAdSDK sharedInstance] loadAd:self.nativeAd];
}

#pragma mark - InneractiveAdDelegate

- (UIViewController *)viewControllerForPresentingModalView {
    // actually, will be never invoked from this class, implementing only to show the right method implementation,
    // and to prevent compiler warning, because this is required interface method;
    //
    // note: after the 'InneractiveAdLoaded:' event will be called, the 'InneractiveNativeAdAdapter' class instance,
    // will take the responsibility of IA ads delegate events
    //
    return self.adAdapter.delegate.viewControllerForPresentingModalView;
}

- (void)InneractiveAdLoaded:(IaAd *)ad { // TODO: MEDIATIONS: perform some logic befor this event, to reduce latency?
    _adAdapter = [[InneractiveNativeAdAdapter alloc] initWithInneractiveNativeAd:(IaNativeAd *)ad];
    MPNativeAd *interfaceAd = [[MPNativeAd alloc] initWithAdAdapter:self.adAdapter];
    
    [self.delegate nativeCustomEvent:self didLoadAd:interfaceAd];
}

- (void)InneractiveAdFailedWithError:(NSError *)error withAdView:(IaAd *)ad {
    if (ad == _nativeAd) { // actually, should be always the same one, just preventing potential third-party bugs
        _nativeAd = nil;
    }
    
    if (error.code == kInneractiveErrorNoInventory) {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:MPNativeAdNSErrorForNoInventory()];
    } else {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:MPNativeAdNSErrorForInvalidAdServerResponse(@"Inneractive ad load error")];
    }
}

@end
